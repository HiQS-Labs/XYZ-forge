Project Driven Doc Automation is a  comprehensive repo document framework designed to provide extended context to AI engines for longer running tasks and phase based project jobs.

To provide the hygeine necessary for automation clarity, the following determinstic scripts should be created, installed, and scheduled for every hour: 

There should be a bash script the moves any doc in 2-WORKING that’s last edit is older than 4 days into 4-misc.

Any doc in the 2-WORKING should have a clear “What was last done and what’s next” column.

A bash script should run that flags docs without that. 

A LLM driven “Doc Ready” script should also flag project plans without QA gates after each phase.

The script should also flag any hardcoded paths in the project plan.