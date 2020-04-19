# Development notes

This markdown is to assist development by keeping track of development
milestones.

## Updates
- Created Expense class data model
- Create singleton SQLite DB handler
- Added DB helper methods
- Wrote test cases for Expense model
- Wrote proof of concept data analytics page
- Fixed issue with wrong runtime casting from List.map()<Type>.toList() in dataTable
- Fixed further issue with runtime casting by switching home_page to stateful widget.
- Fully tested insert() and getAll() functions of DBHandler.
- Created functional routes between home page and form page.
- Created functional test database view using dataTable widget.

## TODO's
- [x] Create singleton SQLite DB handler
- [x] Create homepage data analytics view (Mock)
- [x] Create homepage data analytics view (Functional Mock)
- [x] Create form page
- [x] Write DB handler helper methods
- [x] Complete DB helper methods
- [x] Write doc-strings 
- [x] Create routes for both pages
- [x] Connect database to app
- [ ] Refactor test version app to be modular

## Issues
- [x] None

## current status

- [x] Stable
        : Will run as expected with available features.
- [ ] Tentative
        : Will run but may break/throw runtime errors on some features.
- [ ] Broken
        : Will not run due to unstable code/unhandled errors.