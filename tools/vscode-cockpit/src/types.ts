export interface CardItem {
  id: string;
  title: string;
  badge?: string;
  meta: string[];
  copyValue: string;
  copyLabel: string;
}

export interface Section {
  id: string;
  title: string;
  items: CardItem[];
  emptyMessage: string;
}
