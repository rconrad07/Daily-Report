# Eval Notes from Feb 11

## Overall

- Abandon email service and replace with a go button that initiates the orchestrator, like the @RunNow.bat file. The RunNow.bat file currently does not work because it is asking me for a password that is not available to me. Is it possible to get rid of the password requirement and invoke the orchestrator to run the report.
- Make the arbitor more scrupulous. Identify what good vs bad looks like. Despite the most recent Arbiter evals being 100/100, I disagree based on my eval feedback, which seems to be getting longer and longer.
- Regarding citations, remove the [1] marks from the report. These are not useful since they don't actually correspond to anything. Additionally, only 1 of the 6 linked articles in today's report actually took me to the corresponding article. Otherwise I received a 404 error or homepage.
- There are no previous reports in the left nav bar of the html report - reminder, the search bar should work on the previous reports, not within the open report. I want to be able to search by the day the report was generated (and ideally keywords as a stretch goal). If I want to review a report from the previous month, I should be able to enter a date and the corresponding report should be returned so that I can click on it and view it's contents. This allows me to easily navigate to historical reports and view them.
- The syntax of the md file is far more comprehensible than the html version. They should not be different. In fact, there's no need to continue creating the md version of the report, only create the html version
- Create unit tests to ensure that the report is displayed in the correct sequence: Exec Summary, then the stock watchlist block, followed by the AI Tooling & Experts block, and Hospitality Tech block. Information presented should flow in that order.

## Stock Section

- Include premarket data within the stock section. When I'm running the report at 9am, I'm interested in seeing the premarket data to anticipate where the market (or specific equity) might trend for that day.
- The "Change %" column in the stock table makes no sense. "Featured" is not a change %, neither is "$3.0T". This does not align with the md version of the report.
