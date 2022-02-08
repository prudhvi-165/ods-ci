*** Settings ***
Library  SeleniumLibrary
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Test Setup   Dashboard Test Setup
Test Teardown    Dashboard Test Teardown

*** Variables ***
${user_name} =  //div[@class='pf-c-page__header-tools-item'][3]//span[1]

*** Test Cases ***
Verify "logged in users" are displayed in the dashboard
    [Tags]   Sanity
    ...     ODS-354
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Element Text Should Be    xpath=${user_name}   ${TEST_USER.USERNAME}

*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Dashboard Test Teardown
  Close All Browsers

