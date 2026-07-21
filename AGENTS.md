# Task Monitoring

## Log Polling Limit

For the same running task, do not repeatedly inspect logs. Check logs at most three times in total. The third and final check must use a substantially longer wait than the first two checks. If the task is still running after that final wait, interrupt further polling and wait for the user to observe completion and provide the next instruction.
