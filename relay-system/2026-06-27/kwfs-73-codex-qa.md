# RELAY · QA #73 coupon bulk rebuild (KISS-woo-fast-search)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(kwfs-73-codex-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **kwfs-73-review-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-27

### Artifact — kwfs-73-review-packet.md
````
# QA Review Packet — KISS-woo-fast-search issue #73 (coupon lookup bulk rebuild)

## Context
The coupon-lookup build hydrated every coupon via `new WC_Coupon($id)` (~5-8 queries each) across ~728 rate-limited cron batches; it silently dropped coupons it couldn't hydrate (Klaviyo/Yotpo bulk-generated) and reported success. On a prod copy only ~23k of ~302k published coupons (~7.7%) were indexed.
The fix replaces that with a single-pass bulk rebuild: `rebuild_all()` streams shop_coupon rows from wp_posts in ID-ordered chunks; `bulk_upsert_posts()` writes one multi-row `INSERT ... ON DUPLICATE KEY UPDATE` using the existing `normalize_code()/normalize_text()` for search parity. Backfill + Builder were rewired to use it; the builder runs it as one pass (done=true, no cron fan-out). Hardening added replace-state (clear stale rows, blog-scoped) and fail-loud (a `failed` flag; a non-empty batch that writes 0 rows is treated as a failed bulk write, not a completed run).
Verified on a prod-scale DB copy: coverage 7.7% -> 100% (301,785 published) in ~7s; normalization parity 100% vs the old per-row output.

## Review focus
Correctness of the bulk SQL + chunk cursor; edge cases (empty/huge tables, varchar(200) truncation, code = LOWER(post_title), normalization parity, ON DUPLICATE vs replace-state stale-row cleanup); the failed-flag / fail-loud handling end-to-end (lookup -> backfill -> builder progress/status); concurrency/lock interaction; any silently-incomplete result risk.

## Diff (#73 commits 742df10 + 776d8a3, vs the pre-#73 commit 15a9e89)
```diff
diff --git a/includes/class-kiss-woo-coupon-backfill.php b/includes/class-kiss-woo-coupon-backfill.php
index 395a488..972c795 100644
--- a/includes/class-kiss-woo-coupon-backfill.php
+++ b/includes/class-kiss-woo-coupon-backfill.php
@@ -19,16 +19,17 @@ class KISS_Woo_Coupon_Backfill {
      *
      * @param int $last_id Last processed post ID.
      * @param int $limit   Batch size.
-     * @return array{processed:int,last_id:int,done:bool}
+     * @return array{processed:int,last_id:int,done:bool,failed?:bool}
      */
     public function run_batch( int $last_id = 0, int $limit = 500 ): array {
         global $wpdb;
 
-        $limit = max( 1, min( 2000, $limit ) );
+        $limit = max( 1, min( 5000, $limit ) );
 
-        $ids = $wpdb->get_col(
+        // Fetch the row data directly (no per-coupon WC_Coupon hydration).
+        $rows = $wpdb->get_results(
             $wpdb->prepare(
-                "SELECT ID
+                "SELECT ID, post_title, post_excerpt, post_status
                    FROM {$wpdb->posts}
                   WHERE post_type = 'shop_coupon'
                     AND post_status NOT IN ('trash', 'auto-draft')
@@ -40,7 +41,7 @@ class KISS_Woo_Coupon_Backfill {
             )
         );
 
-        if ( empty( $ids ) ) {
+        if ( empty( $rows ) ) {
             return array(
                 'processed' => 0,
                 'last_id'   => $last_id,
@@ -48,22 +49,28 @@ class KISS_Woo_Coupon_Backfill {
             );
         }
 
-        $lookup = KISS_Woo_Coupon_Lookup::instance();
-        $processed = 0;
-        $current_last = $last_id;
+        // Single bulk multi-row upsert for the whole batch.
+        $processed = KISS_Woo_Coupon_Lookup::instance()->bulk_upsert_posts( $rows );
 
-        foreach ( $ids as $id ) {
-            $id = (int) $id;
-            if ( $lookup->upsert_coupon( $id ) ) {
-                $processed++;
-            }
-            $current_last = $id;
+        // A non-empty batch that wrote nothing means the bulk INSERT failed.
+        // Do not advance past it or mark the run done — surface the failure so
+        // the same batch is retried rather than silently skipped.
+        if ( 0 === $processed ) {
+            return array(
+                'processed' => 0,
+                'last_id'   => $last_id,
+                'done'      => false,
+                'failed'    => true,
+            );
         }
 
+        $last_row     = end( $rows );
+        $current_last = (int) $last_row->ID;
+
         return array(
             'processed' => $processed,
             'last_id'   => $current_last,
-            'done'      => count( $ids ) < $limit,
+            'done'      => count( $rows ) < $limit,
         );
     }
 }
diff --git a/includes/class-kiss-woo-coupon-lookup-builder.php b/includes/class-kiss-woo-coupon-lookup-builder.php
index c01a9d7..e18f102 100644
--- a/includes/class-kiss-woo-coupon-lookup-builder.php
+++ b/includes/class-kiss-woo-coupon-lookup-builder.php
@@ -194,46 +194,73 @@ class KISS_Woo_Coupon_Lookup_Builder {
 		}
 
 		try {
-			// Get current progress.
-			$progress = $this->get_progress();
-
-			// If idle, initialize.
-			if ( 'idle' === $progress['status'] || 0 === $progress['total'] ) {
-				$progress['total']      = $this->get_total_coupons();
-				$progress['started_at'] = time();
-				$progress['status']     = 'running';
-				$this->update_progress( $progress );
-			}
-
-			// Run batch using existing backfill class.
-			$backfill = new KISS_Woo_Coupon_Backfill();
-			$result   = $backfill->run_batch( $progress['last_id'], $batch_size );
-
-			// Update progress.
-			$progress['last_id']   = $result['last_id'];
-			$progress['processed'] += $result['processed'];
+			// Single-pass bulk rebuild. Replaces the per-coupon WC_Coupon
+			// hydration loop (which silently dropped ~92% of coupons and took
+			// 12+ hours across ~728 rate-limited cron batches). rebuild_all()
+			// streams wp_posts in chunks and bulk-upserts, finishing the whole
+			// table in one cron run in seconds — so done is always true and no
+			// follow-up batch is scheduled.
+			$total  = $this->get_total_coupons();
+			$lookup = KISS_Woo_Coupon_Lookup::instance();
+
+			$this->update_progress(
+				array(
+					'last_id'    => 0,
+					'processed'  => 0,
+					'total'      => $total,
+					'started_at' => time(),
+					'status'     => 'running',
+				)
+			);
 
-			if ( $result['done'] ) {
-				$progress['status'] = 'complete';
+			$chunk  = max( 500, min( 5000, $batch_size > 0 ? $batch_size : 2000 ) );
+			$result = $lookup->rebuild_all( $chunk );
+
+			// A failed bulk write must not be reported as a complete rebuild.
+			// Stamp the job 'error' and leave it not-done so it can be retried.
+			if ( ! empty( $result['failed'] ) ) {
+				$this->update_progress(
+					array(
+						'last_id'    => $result['last_id'],
+						'processed'  => $result['inserted'],
+						'total'      => $total,
+						'started_at' => time(),
+						'status'     => 'error',
+					)
+				);
+
+				return array(
+					'success'   => false,
+					'processed' => $result['inserted'],
+					'last_id'   => $result['last_id'],
+					'done'      => false,
+					'message'   => sprintf(
+						'Coupon rebuild failed after %d of %d coupons (bulk write error)',
+						$result['inserted'],
+						$total
+					),
+				);
 			}
 
-			$this->update_progress( $progress );
-
-			// Set next run time (rate limiting for background jobs).
-			if ( ! $result['done'] ) {
-				$this->set_next_run( self::MIN_RUN_INTERVAL );
-			}
+			$this->update_progress(
+				array(
+					'last_id'    => $result['last_id'],
+					'processed'  => $result['inserted'],
+					'total'      => $total,
+					'started_at' => time(),
+					'status'     => 'complete',
+				)
+			);
 
 			return array(
 				'success'   => true,
-				'processed' => $result['processed'],
+				'processed' => $result['inserted'],
 				'last_id'   => $result['last_id'],
-				'done'      => $result['done'],
+				'done'      => true,
 				'message'   => sprintf(
-					'Processed %d coupons (total: %d/%d)',
-					$result['processed'],
-					$progress['processed'],
-					$progress['total']
+					'Rebuilt %d coupons in a single bulk pass (total: %d)',
+					$result['inserted'],
+					$total
 				),
 			);
 
diff --git a/includes/class-kiss-woo-coupon-lookup.php b/includes/class-kiss-woo-coupon-lookup.php
index 2e65819..72e5bc7 100644
--- a/includes/class-kiss-woo-coupon-lookup.php
+++ b/includes/class-kiss-woo-coupon-lookup.php
@@ -246,6 +246,179 @@ class KISS_Woo_Coupon_Lookup {
         return false !== $result;
     }
 
+    /**
+     * Rebuild the entire lookup table directly from wp_posts in bulk.
+     *
+     * Replaces the per-coupon `new WC_Coupon()` hydration path (which issues
+     * ~5-8 queries per coupon and silently drops coupons WC_Coupon can't
+     * hydrate). This streams shop_coupon posts in ID-ordered chunks and writes
+     * multi-row upserts, so every published coupon is indexed (1:1) in seconds
+     * rather than hours. Only the 5 search-used columns + identity/status are
+     * populated; the unused metadata columns keep their schema defaults.
+     *
+     * Normalization uses the same normalize_code()/normalize_text() the search
+     * path uses, so code_normalized/description_normalized stay query-compatible
+     * (a pure SQL INSERT...SELECT could not replicate the regex/tag stripping
+     * portably across MySQL versions).
+     *
+     * @param int $chunk Rows per batch (bounded memory + statement size).
+     * @return array{inserted:int,last_id:int,pruned:int,failed:bool} Summary of
+     *               the rebuild. `pruned` counts stale rows removed; `failed` is
+     *               true if a bulk write failed (prune skipped, retry needed).
+     */
+    public function rebuild_all( int $chunk = 2000 ): array {
+        if ( ! $this->ensure_table_ready() ) {
+            return array( 'inserted' => 0, 'last_id' => 0 );
+        }
+
+        global $wpdb;
+
+        $posts    = $wpdb->posts;
+        $table    = $this->get_table_name();
+        $blog_id  = (int) get_current_blog_id();
+        $chunk    = max( 100, $chunk );
+        $last_id  = 0;
+        $inserted = 0;
+        $failed   = false;
+
+        do {
+            // Stream coupons in ID order — no WC_Coupon, no postmeta JOINs.
+            $rows = $wpdb->get_results(
+                $wpdb->prepare(
+                    "SELECT ID, post_title, post_excerpt, post_status
+                     FROM {$posts}
+                     WHERE post_type = 'shop_coupon'
+                       AND post_status NOT IN ('trash', 'auto-draft')
+                       AND ID > %d
+                     ORDER BY ID ASC
+                     LIMIT %d",
+                    $last_id,
+                    $chunk
+                )
+            );
+
+            $batch = is_array( $rows ) ? count( $rows ) : 0;
+            if ( 0 === $batch ) {
+                break;
+            }
+
+            $written = $this->bulk_upsert_posts( $rows );
+
+            // A non-empty batch that writes nothing means the bulk INSERT failed.
+            // Abort and skip the prune below so we never delete rows we could not
+            // re-insert (the table degrades gracefully rather than losing data).
+            if ( 0 === $written ) {
+                $failed = true;
+                break;
+            }
+
+            $inserted += $written;
+            $last_row  = end( $rows );
+            $last_id   = (int) $last_row->ID;
+            reset( $rows );
+        } while ( $batch === $chunk );
+
+        // Prune rows that no longer correspond to a live coupon (trashed or
+        // deleted since the last rebuild). Without this, rebuild_all() is a
+        // merge — stale rows stay searchable and the table drifts from being a
+        // 1:1 projection of live shop_coupon posts. Mirrors the SELECT criteria
+        // above, scoped to this blog. Skipped on a failed write.
+        $pruned = 0;
+        if ( ! $failed ) {
+            $pruned = (int) $wpdb->query(
+                $wpdb->prepare(
+                    "DELETE FROM {$table}
+                     WHERE blog_id = %d
+                       AND coupon_id NOT IN (
+                           SELECT ID FROM {$posts}
+                           WHERE post_type = 'shop_coupon'
+                             AND post_status NOT IN ('trash', 'auto-draft')
+                       )",
+                    $blog_id
+                )
+            );
+        }
+
+        return array(
+            'inserted' => $inserted,
+            'last_id'  => $last_id,
+            'pruned'   => $pruned,
+            'failed'   => $failed,
+        );
+    }
+
+    /**
+     * Bulk-upsert a set of shop_coupon post rows into the lookup table.
+     *
+     * Shared write path for rebuild_all() and the backfill batch processor.
+     * Each row must expose ID, post_title, post_excerpt, post_status. Writes
+     * one multi-row INSERT ... ON DUPLICATE KEY UPDATE — no per-row WC_Coupon
+     * hydration, so nothing is silently dropped.
+     *
+     * @param array $rows Raw post rows (objects from $wpdb->get_results).
+     * @return int Number of rows written.
+     */
+    public function bulk_upsert_posts( array $rows ): int {
+        if ( empty( $rows ) || ! $this->ensure_table_ready() ) {
+            return 0;
+        }
+
+        global $wpdb;
+
+        $table   = $this->get_table_name();
+        $blog_id = (int) get_current_blog_id();
+        $now     = current_time( 'mysql', true );
+
+        $placeholders = array();
+        $params       = array();
+
+        foreach ( $rows as $r ) {
+            // WC stores the coupon code in post_title (lower-cased on read).
+            $code  = strtolower( (string) $r->post_title );
+            $title = (string) $r->post_title;
+            $desc  = (string) $r->post_excerpt;
+
+            $placeholders[] = '(%d, %d, %s, %s, %s, %s, %s, %s, %s)';
+            array_push(
+                $params,
+                (int) $r->ID,
+                $blog_id,
+                // VARCHAR(200) columns — truncate to avoid strict-mode overflow.
+                mb_substr( $code, 0, 200 ),
+                mb_substr( self::normalize_code( $code ), 0, 200 ),
+                mb_substr( $title, 0, 200 ),
+                $desc,
+                self::normalize_text( $desc ),
+                (string) $r->post_status,
+                $now
+            );
+        }
+
+        $sql = "INSERT INTO {$table}
+                    (coupon_id, blog_id, code, code_normalized, title, description, description_normalized, status, updated_at)
+                VALUES " . implode( ', ', $placeholders ) . "
+                ON DUPLICATE KEY UPDATE
+                    code = VALUES(code),
+                    code_normalized = VALUES(code_normalized),
+                    title = VALUES(title),
+                    description = VALUES(description),
+                    description_normalized = VALUES(description_normalized),
+                    status = VALUES(status),
+                    updated_at = VALUES(updated_at)";
+
+        // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- placeholders built above, values bound via prepare().
+        $result = $wpdb->query( $wpdb->prepare( $sql, $params ) );
+
+        // $wpdb->query() returns false on a failed write. Return 0 so callers
+        // (rebuild_all / the backfill batch) never count a failed batch as
+        // indexed, and never stamp the job complete on a broken write.
+        if ( false === $result ) {
+            return 0;
+        }
+
+        return count( $rows );
+    }
+
     /**
      * Delete a coupon from the lookup table.
      *
```

## Full current source — includes/class-kiss-woo-coupon-lookup.php (rebuild_all + bulk_upsert_posts core)
```php
<?php
/**
 * Coupon lookup table and indexing.
 *
 * SINGLE WRITE PATH: All coupon lookup writes go through this class.
 *
 * @package KISS_Woo_Customer_Order_Search
 * @since   1.3.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class KISS_Woo_Coupon_Lookup {

    /**
     * Schema version for the coupon lookup table.
     *
     * @var string
     */
    private const DB_VERSION = '1.1';

    /**
     * Option name that stores the schema version.
     *
     * @var string
     */
    private const DB_OPTION = 'kiss_woo_coupon_lookup_db_version';

    /**
     * Singleton instance.
     *
     * @var KISS_Woo_Coupon_Lookup|null
     */
    protected static $instance = null;

    /**
     * Track whether the table exists to avoid redundant checks.
     *
     * @var bool
     */
    private bool $table_ready = false;

    /**
     * Get singleton instance.
     *
     * @return KISS_Woo_Coupon_Lookup
     */
    public static function instance() {
        if ( null === self::$instance ) {
            self::$instance = new self();
        }

        return self::$instance;
    }

    /**
     * Constructor.
     */
    private function __construct() {
        add_action( 'admin_init', array( $this, 'maybe_install' ) );
        add_action( 'save_post_shop_coupon', array( $this, 'handle_coupon_save' ), 10, 3 );
        add_action( 'before_delete_post', array( $this, 'handle_coupon_delete' ) );
        add_action( 'trashed_post', array( $this, 'handle_coupon_delete' ) );
        add_action( 'untrashed_post', array( $this, 'handle_coupon_untrash' ) );
    }

    /**
     * Get the lookup table name.
     *
     * @return string
     */
    public function get_table_name(): string {
        global $wpdb;

        return $wpdb->prefix . 'kiss_woo_coupon_lookup';
    }

    /**
     * Ensure the lookup table exists and is up to date.
     *
     * @return void
     */
    public function maybe_install(): void {
        if ( $this->table_ready ) {
            return;
        }

        $installed_version = get_option( self::DB_OPTION, '' );
        if ( self::DB_VERSION === $installed_version && $this->table_exists() ) {
            $this->table_ready = true;
            return;
        }

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';

        dbDelta( $this->get_schema_sql() );
        update_option( self::DB_OPTION, self::DB_VERSION );
        $this->table_ready = true;
    }

    /**
     * Handle coupon save/update.
     *
     * @param int     $post_id Post ID.
     * @param WP_Post $post    Post object.
     * @param bool    $update  Whether this is an update.
     * @return void
     */
    public function handle_coupon_save( $post_id, $post, $update ): void {
        if ( wp_is_post_revision( $post_id ) || wp_is_post_autosave( $post_id ) ) {
            return;
        }

        if ( empty( $post ) || 'shop_coupon' !== $post->post_type ) {
            return;
        }

        if ( 'trash' === $post->post_status || 'auto-draft' === $post->post_status ) {
            $this->delete_coupon( (int) $post_id );
            return;
        }

        $this->upsert_coupon( (int) $post_id );
    }

    /**
     * Handle coupon deletion or trashing.
     *
     * @param int $post_id Post ID.
     * @return void
     */
    public function handle_coupon_delete( $post_id ): void {
        $post = get_post( $post_id );
        if ( ! $post || 'shop_coupon' !== $post->post_type ) {
            return;
        }

        $this->delete_coupon( (int) $post_id );
    }

    /**
     * Handle coupon untrash.
     *
     * @param int $post_id Post ID.
     * @return void
     */
    public function handle_coupon_untrash( $post_id ): void {
        $post = get_post( $post_id );
        if ( ! $post || 'shop_coupon' !== $post->post_type ) {
            return;
        }

        $this->upsert_coupon( (int) $post_id );
    }

    /**
     * Upsert a coupon into the lookup table.
     *
     * @param int $coupon_id Coupon ID.
     * @return bool
     */
    public function upsert_coupon( int $coupon_id ): bool {
        $debug = defined( 'WP_CLI' ) && WP_CLI;

        if ( $coupon_id <= 0 ) {
            if ( $debug ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): invalid coupon_id" );
            }
            return false;
        }

        if ( ! $this->ensure_table_ready() ) {
            if ( $debug ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): table not ready" );
            }
            return false;
        }

        // Use WC_Coupon class directly instead of wc_get_coupon() helper function
        // The helper function may not be loaded in all contexts (e.g., WP-CLI)
        if ( ! class_exists( 'WC_Coupon' ) ) {
            if ( $debug ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): WC_Coupon class not found" );
            }
            return false;
        }

        try {
            $coupon = new WC_Coupon( $coupon_id );
        } catch ( Exception $e ) {
            if ( $debug ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): Exception creating WC_Coupon: " . $e->getMessage() );
            }
            return false;
        }

        if ( ! $coupon || ! $coupon->get_id() ) {
            if ( $debug ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): failed to load WC_Coupon object or invalid ID" );
            }
            return false;
        }

        $row = $this->build_row_from_coupon( $coupon );
        if ( empty( $row ) ) {
            if ( $debug ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): build_row_from_coupon returned empty" );
            }
            return false;
        }

        global $wpdb;

        $format = array(
            '%d', // coupon_id
            '%d', // blog_id
            '%s', // code
            '%s', // code_normalized
            '%s', // title
            '%s', // description
            '%s', // description_normalized
            '%f', // amount
            '%s', // discount_type
            '%s', // expiry_date
            '%d', // usage_limit
            '%d', // usage_limit_per_user
            '%d', // usage_count
            '%d', // free_shipping
            '%s', // status
            '%s', // source_flags
            '%s', // updated_at
        );

        $result = $wpdb->replace( $this->get_table_name(), $row, $format );

        if ( $debug ) {
            if ( false === $result ) {
                WP_CLI::debug( "upsert_coupon($coupon_id): wpdb->replace failed. Error: " . $wpdb->last_error );
            } else {
                WP_CLI::debug( "upsert_coupon($coupon_id): SUCCESS" );
            }
        }

        return false !== $result;
    }

    /**
     * Rebuild the entire lookup table directly from wp_posts in bulk.
     *
     * Replaces the per-coupon `new WC_Coupon()` hydration path (which issues
     * ~5-8 queries per coupon and silently drops coupons WC_Coupon can't
     * hydrate). This streams shop_coupon posts in ID-ordered chunks and writes
     * multi-row upserts, so every published coupon is indexed (1:1) in seconds
     * rather than hours. Only the 5 search-used columns + identity/status are
     * populated; the unused metadata columns keep their schema defaults.
     *
     * Normalization uses the same normalize_code()/normalize_text() the search
     * path uses, so code_normalized/description_normalized stay query-compatible
     * (a pure SQL INSERT...SELECT could not replicate the regex/tag stripping
     * portably across MySQL versions).
     *
     * @param int $chunk Rows per batch (bounded memory + statement size).
     * @return array{inserted:int,last_id:int,pruned:int,failed:bool} Summary of
     *               the rebuild. `pruned` counts stale rows removed; `failed` is
     *               true if a bulk write failed (prune skipped, retry needed).
     */
    public function rebuild_all( int $chunk = 2000 ): array {
        if ( ! $this->ensure_table_ready() ) {
            return array( 'inserted' => 0, 'last_id' => 0 );
        }

        global $wpdb;

        $posts    = $wpdb->posts;
        $table    = $this->get_table_name();
        $blog_id  = (int) get_current_blog_id();
        $chunk    = max( 100, $chunk );
        $last_id  = 0;
        $inserted = 0;
        $failed   = false;

        do {
            // Stream coupons in ID order — no WC_Coupon, no postmeta JOINs.
            $rows = $wpdb->get_results(
                $wpdb->prepare(
                    "SELECT ID, post_title, post_excerpt, post_status
                     FROM {$posts}
                     WHERE post_type = 'shop_coupon'
                       AND post_status NOT IN ('trash', 'auto-draft')
                       AND ID > %d
                     ORDER BY ID ASC
                     LIMIT %d",
                    $last_id,
                    $chunk
                )
            );

            $batch = is_array( $rows ) ? count( $rows ) : 0;
            if ( 0 === $batch ) {
                break;
            }

            $written = $this->bulk_upsert_posts( $rows );

            // A non-empty batch that writes nothing means the bulk INSERT failed.
            // Abort and skip the prune below so we never delete rows we could not
            // re-insert (the table degrades gracefully rather than losing data).
            if ( 0 === $written ) {
                $failed = true;
                break;
            }

            $inserted += $written;
            $last_row  = end( $rows );
            $last_id   = (int) $last_row->ID;
            reset( $rows );
        } while ( $batch === $chunk );

        // Prune rows that no longer correspond to a live coupon (trashed or
        // deleted since the last rebuild). Without this, rebuild_all() is a
        // merge — stale rows stay searchable and the table drifts from being a
        // 1:1 projection of live shop_coupon posts. Mirrors the SELECT criteria
        // above, scoped to this blog. Skipped on a failed write.
        $pruned = 0;
        if ( ! $failed ) {
            $pruned = (int) $wpdb->query(
                $wpdb->prepare(
                    "DELETE FROM {$table}
                     WHERE blog_id = %d
                       AND coupon_id NOT IN (
                           SELECT ID FROM {$posts}
                           WHERE post_type = 'shop_coupon'
                             AND post_status NOT IN ('trash', 'auto-draft')
                       )",
                    $blog_id
                )
            );
        }

        return array(
            'inserted' => $inserted,
            'last_id'  => $last_id,
            'pruned'   => $pruned,
            'failed'   => $failed,
        );
    }

    /**
     * Bulk-upsert a set of shop_coupon post rows into the lookup table.
     *
     * Shared write path for rebuild_all() and the backfill batch processor.
     * Each row must expose ID, post_title, post_excerpt, post_status. Writes
     * one multi-row INSERT ... ON DUPLICATE KEY UPDATE — no per-row WC_Coupon
     * hydration, so nothing is silently dropped.
     *
     * @param array $rows Raw post rows (objects from $wpdb->get_results).
     * @return int Number of rows written.
     */
    public function bulk_upsert_posts( array $rows ): int {
        if ( empty( $rows ) || ! $this->ensure_table_ready() ) {
            return 0;
        }

        global $wpdb;

        $table   = $this->get_table_name();
        $blog_id = (int) get_current_blog_id();
        $now     = current_time( 'mysql', true );

        $placeholders = array();
        $params       = array();

        foreach ( $rows as $r ) {
            // WC stores the coupon code in post_title (lower-cased on read).
            $code  = strtolower( (string) $r->post_title );
            $title = (string) $r->post_title;
            $desc  = (string) $r->post_excerpt;

            $placeholders[] = '(%d, %d, %s, %s, %s, %s, %s, %s, %s)';
            array_push(
                $params,
                (int) $r->ID,
                $blog_id,
                // VARCHAR(200) columns — truncate to avoid strict-mode overflow.
                mb_substr( $code, 0, 200 ),
                mb_substr( self::normalize_code( $code ), 0, 200 ),
                mb_substr( $title, 0, 200 ),
                $desc,
                self::normalize_text( $desc ),
                (string) $r->post_status,
                $now
            );
        }

        $sql = "INSERT INTO {$table}
                    (coupon_id, blog_id, code, code_normalized, title, description, description_normalized, status, updated_at)
                VALUES " . implode( ', ', $placeholders ) . "
                ON DUPLICATE KEY UPDATE
                    code = VALUES(code),
                    code_normalized = VALUES(code_normalized),
                    title = VALUES(title),
                    description = VALUES(description),
                    description_normalized = VALUES(description_normalized),
                    status = VALUES(status),
                    updated_at = VALUES(updated_at)";

        // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- placeholders built above, values bound via prepare().
        $result = $wpdb->query( $wpdb->prepare( $sql, $params ) );

        // $wpdb->query() returns false on a failed write. Return 0 so callers
        // (rebuild_all / the backfill batch) never count a failed batch as
        // indexed, and never stamp the job complete on a broken write.
        if ( false === $result ) {
            return 0;
        }

        return count( $rows );
    }

    /**
     * Delete a coupon from the lookup table.
     *
     * @param int $coupon_id Coupon ID.
     * @return bool
     */
    public function delete_coupon( int $coupon_id ): bool {
        if ( $coupon_id <= 0 ) {
            return false;
        }

        if ( ! $this->ensure_table_ready() ) {
            return false;
        }

        global $wpdb;

        $result = $wpdb->delete(
            $this->get_table_name(),
            array(
                'coupon_id' => $coupon_id,
            ),
            array( '%d' )
        );

        return false !== $result;
    }

    /**
     * Build a lookup row from a WooCommerce coupon object.
     *
     * @param WC_Coupon $coupon Coupon object.
     * @return array
     */
    private function build_row_from_coupon( WC_Coupon $coupon ): array {
        $coupon_id = (int) $coupon->get_id();
        $code      = (string) $coupon->get_code();
        $title     = (string) get_the_title( $coupon_id );
        $desc      = (string) $coupon->get_description();
        $expires   = $coupon->get_date_expires();
        $status    = (string) get_post_status( $coupon_id );

        $row = array(
            'coupon_id'             => $coupon_id,
            'blog_id'               => (int) get_current_blog_id(),
            'code'                  => $code,
            'code_normalized'       => self::normalize_code( $code ),
            'title'                 => $title,
            'description'           => $desc,
            'description_normalized'=> self::normalize_text( $desc ),
            'amount'                => (float) $coupon->get_amount(),
            'discount_type'         => (string) $coupon->get_discount_type(),
            'expiry_date'           => $expires ? $expires->date( 'Y-m-d H:i:s' ) : null,
            'usage_limit'           => $coupon->get_usage_limit(),
            'usage_limit_per_user'  => $coupon->get_usage_limit_per_user(),
            'usage_count'           => $coupon->get_usage_count(),
            'free_shipping'         => $coupon->get_free_shipping() ? 1 : 0,
            'status'                => $status ? $status : 'publish',
            'source_flags'          => implode( ',', $this->get_source_flags( $coupon ) ),
            'updated_at'            => current_time( 'mysql', true ),
        );

        /**
         * Allow other code to modify the lookup row before save.
         *
         * @param array     $row    Lookup row.
         * @param WC_Coupon $coupon Coupon object.
         */
        return apply_filters( 'kiss_woo_coupon_lookup_row', $row, $coupon );
    }

    /**
     * Determine source flags for a coupon.
     *
     * @param WC_Coupon $coupon Coupon object.
     * @return array
     */
    private function get_source_flags( WC_Coupon $coupon ): array {
        $flags = array( 'core' );

        $meta_map = apply_filters(
            'kiss_woo_coupon_source_meta_keys',
            array(
                'smart'    => array(),
                'advanced' => array(),
            )
        );

        foreach ( $meta_map as $flag => $keys ) {
            foreach ( (array) $keys as $key ) {
                if ( '' !== $coupon->get_meta( $key, true ) ) {
                    $flags[] = (string) $flag;
                    break;
                }
            }
        }

        /**
         * Allow other code to adjust source flags.
         *
         * @param array     $flags  Source flags.
         * @param WC_Coupon $coupon Coupon object.
         */
        $flags = apply_filters( 'kiss_woo_coupon_source_flags', $flags, $coupon );

        return array_values( array_unique( $flags ) );
    }

    /**
     * Normalize coupon code for indexed search.
     *
     * @param string $code Coupon code.
     * @return string
     */
    public static function normalize_code( string $code ): string {
        $code = strtolower( trim( $code ) );
        $code = preg_replace( '/[^a-z0-9]+/', '', $code );

        return $code;
    }

    /**
     * Normalize general text for indexed search.
     *
     * @param string $text Raw text.
     * @return string
     */
    public static function normalize_text( string $text ): string {
        $text = wp_strip_all_tags( $text );
        $text = strtolower( trim( $text ) );
        $text = preg_replace( '/\\s+/', ' ', $text );

        return $text;
    }

    /**
     * Check if the lookup table exists.
     *
     * @return bool
     */
    private function table_exists(): bool {
        global $wpdb;

        $table  = $this->get_table_name();
        $exists = $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $table ) );

        return $exists === $table;
    }

    /**
     * Ensure the lookup table is ready.
     *
     * @return bool
     */
    private function ensure_table_ready(): bool {
        if ( $this->table_ready ) {
            return true;
        }

        if ( $this->table_exists() ) {
            $this->table_ready = true;
            return true;
        }

        $this->maybe_install();

        return $this->table_exists();
    }

    /**
     * Public check for table readiness.
     *
     * @return bool
     */
    public function is_table_ready(): bool {
        return $this->ensure_table_ready();
    }

    /**
     * Get the SQL schema for the lookup table.
     *
     * @return string
     */
    private function get_schema_sql(): string {
        global $wpdb;

        $table_name      = $this->get_table_name();
        $charset_collate = $wpdb->get_charset_collate();

        return "CREATE TABLE {$table_name} (
            coupon_id BIGINT UNSIGNED NOT NULL,
            blog_id BIGINT UNSIGNED NOT NULL DEFAULT 1,
            code VARCHAR(200) NOT NULL DEFAULT '',
            code_normalized VARCHAR(200) NOT NULL DEFAULT '',
            title VARCHAR(200) NOT NULL DEFAULT '',
            description TEXT NULL,
            description_normalized TEXT NULL,
            amount DECIMAL(19,4) NULL,
            discount_type VARCHAR(50) NULL,
            expiry_date DATETIME NULL,
            usage_limit INT NULL,
            usage_limit_per_user INT NULL,
            usage_count INT NULL,
            free_shipping TINYINT(1) NOT NULL DEFAULT 0,
            status VARCHAR(20) NOT NULL DEFAULT 'publish',
            source_flags VARCHAR(100) NOT NULL DEFAULT 'core',
            updated_at DATETIME NOT NULL,
            PRIMARY KEY  (coupon_id),
            KEY idx_code_normalized (code_normalized),
            KEY idx_title (title),
            KEY idx_expiry (expiry_date),
            KEY idx_blog_id (blog_id),
            FULLTEXT KEY idx_search_fulltext (code_normalized, title, description_normalized)
        ) {$charset_collate};";
    }
}
```
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
