# sh run_robot_test.sh --extra-robot-args '-i ODS-1072'
*** Settings ***
Library  SeleniumLibrary
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Test Setup   Dashboard Test Setup
Test Teardown    Dashboard Test Teardown

*** Variables ***
${url} =   https://console-openshift-console.apps.qeaisrhods9.i9jt.s1.devshift.org/
${browser} =  chrome
${username} =  ldap-admin11
${password} =   rhodsPW#1

*** Test Cases ***
verify login
    [Tags]   ODS-1072
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Element Text Should Be    xpath=//div[@class='pf-c-page__header-tools-item'][3]//span[1]   ldap-admin11


*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Dashboard Test Teardown
  Close All Browsers

