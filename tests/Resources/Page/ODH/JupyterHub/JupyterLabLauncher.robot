*** Settings ***
Library  JupyterLibrary
Library  jupyter-helper.py
Library  OperatingSystem

*** Variables ***
${JL_TABBAR_CONTENT_XPATH} =  //div[contains(@class,"lm-DockPanel-tabBar")]/ul[@class="lm-TabBar-content p-TabBar-content"]
${JL_TABBAR_SELECTED_XPATH} =  ${JL_TABBAR_CONTENT_XPATH}/li[contains(@class,"lm-mod-current p-mod-current")]
${JL_TABBAR_NOT_SELECTED_XPATH} =  ${JL_TABBAR_CONTENT_XPATH}/li[not(contains(@class,"lm-mod-current p-mod-current"))]

*** Keywords ***
Get JupyterLab Selected Tab Label
  ${tab_label} =  Get Text  ${JL_TABBAR_SELECTED_XPATH}/div[contains(@class,"p-TabBar-tabLabel")]
  [return]  ${tab_label}

JupyterLab Launcher Tab Is Visible
  Get WebElement  xpath:${JL_TABBAR_CONTENT_XPATH}/li/div[.="Launcher"]

JupyterLab Launcher Tab Is Selected
  Get WebElement  xpath:${JL_TABBAR_SELECTED_XPATH}/div[.="Launcher"]

Open JupyterLab Launcher
  Open With JupyterLab Menu  File  New Launcher
  JupyterLab Launcher Tab Is Visible
  JupyterLab Launcher Tab Is Selected

Wait Until ${filename} JupyterLab Tab Is Selected
  Wait Until Page Contains Element  xpath:${JL_TABBAR_SELECTED_XPATH}/div[.="${filename}"]

Close Other JupyterLab Tabs
  ${original_tab} =  Get WebElement  xpath:${JL_TABBAR_SELECTED_XPATH}/div[contains(@class, "p-TabBar-tabLabel")]

  ${xpath_background_tab} =  Set Variable  xpath:${JL_TABBAR_NOT_SELECTED_XPATH}
  ${jl_tabs} =  Get WebElements  ${xpath_background_tab}

  FOR  ${tab}  IN  @{jl_tabs}
    #Select the tab we want to close
    Click Element  ${tab}
    #Click the close tab icon
    Open With JupyterLab Menu  File  Close Tab
    Maybe Save Changes
  END
  Sleep  2
  Element Should Be Visible  ${original_tab}
  Element Should Not Be Visible  ${xpath_background_tab}

Close JupyterLab Selected Tab
  Click Element  xpath:${JL_TABBAR_SELECTED_XPATH}/div[contains(@class,"lm-TabBar-tabCloseIcon")]
  Maybe Save Changes

JupyterLab Code Cell Error Output Should Not Be Visible
  Element Should Not Be Visible  xpath://div[contains(@class,"jp-OutputArea-output") and @data-mime-type="application/vnd.jupyter.stderr"]  A JupyterLab code cell output returned an error

Get JupyterLab Code Cell Error Text
  ${error_txt} =  Get Text  //div[contains(@class,"jp-OutputArea-output") and @data-mime-type="application/vnd.jupyter.stderr"]
  [Return]

Wait Until JupyterLab Code Cell Is Not Active
  [Documentation]  Waits until the current cell no longer has an active prompt "[*]:". This assumes that there is only one cell currently active and it is the currently selected cell
  [Arguments]  ${timeout}=120seconds
  Wait Until Element Is Not Visible  //div[contains(@class,"jp-Cell-inputArea")]/div[contains(@class,"jp-InputArea-prompt") and (.="[*]:")][1]  ${timeout}

Select Empty JupyterLab Code Cell
  Click Element  //div[contains(@class,"jp-mod-noOutputs jp-Notebook-cell")]

Start JupyterLab Notebook Server
  Open JupyterHub Control Panel
  Click Link  start

Open JupyterLab Control Panel
  Open With JupyterLab Menu  File  Hub Control Panel
  Switch Window  JupyterHub

Stop JupyterLab Notebook Server
  Open JupyterLab Control Panel
  Run Keyword And Ignore Error   Wait Until Page Contains  Stop My Server   timeout=30
  # This is a dumb sleep to give the Stop button in the WebUI time to actually work when clicked
  # TODO: Determine if there is any web element attribute that will allow signify when the Stop button will actually work
  Sleep  2 seconds
  Capture Page Screenshot
  ${stop_enabled} =  Run Keyword And Return Status  Page Should Contain Element    //*[@id="stop"]
  IF    ${stop_enabled} == True
    Click Element  //*[@id="stop"]
    Wait Until Element Is Not Visible   //*[@id="stop"]  3 minute
    Wait Until Page Contains  Start My Server  timeout=120
    Capture Page Screenshot
  END


Logout JupyterLab
  Open With JupyterLab Menu  File  Log Out

Run Cell And Check For Errors
  [Arguments]  ${input}
  Add and Run JupyterLab Code Cell  ${input}
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*

Run Cell And Check Output
  [Arguments]  ${input}  ${expected_output}
  Add and Run JupyterLab Code Cell  ${input}
  Wait Until JupyterLab Code Cell Is Not Active
  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Match  ${output}  ${expected_output}

Maybe Select Kernel
  ${is_kernel_selected} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]
  Run Keyword If  not ${is_kernel_selected}  Click Button  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]/..

Clean Up Server
  Maybe Save Changes
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  File  New  Notebook
  Sleep  1
  Maybe Select Kernel
  Close Other JupyterLab Tabs
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  Untitled.ipynb
  Click Element  xpath://div[.="Open"]
  Sleep  1
  Maybe Select Kernel
  Wait Until Untitled.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Add and Run JupyterLab Code Cell  !rm -rf *


Get User Notebook Pod Name
  [Documentation]   Returns notebook pod name for given username  (e.g. for user ldap-admin1 it will be jupyterhub-nb-ldap-2dadmin1)
  [Arguments]  ${username}
  ${safe_username}=  Get Safe Username    ${username}
  ${notebook_pod_name}=   Set Variable  jupyterhub-nb-${safe_username}
  [Return]  ${notebook_pod_name}

Clean Up User Notebook
  [Documentation]  Delete all files and folders in the ${username}'s notebook PVC (excluding hidden files and folders).
...   Note: this command requires ${admin_username}  to be logged to the cluster (oc login ...) and to have the user's notebook pod running (e.g. jupyterhub-nb-ldap-2duser1)
  [Arguments]  ${admin_username}  ${username}

  # Verify that ${admin_username}  is connected to the cluster
  ${oc_whoami}=  Run   oc whoami
  IF    '${oc_whoami}' == '${admin_username}'
      # We import the library here so it's loaded only when we are connected to the cluster
      # Having the usual "Library OpenShiftCLI" in the header raises an error when loading the file
      # if there is not any connection opened
      Import Library    OpenShiftCLI

      # Verify that the jupyter notebook pod is running
      ${notebook_pod_name}=   Get User Notebook Pod Name  ${username}
      Search Pods    ${notebook_pod_name}  namespace=rhods-notebooks

      # Delete all files and folders in /opt/app-root/src/  (excluding hidden files/folders)
      # Note: rm -fr /opt/app-root/src/ or rm -fr /opt/app-root/src/* didn't work properly so we ended up using find
      ${output}=  Run   oc exec ${notebook_pod_name} -n rhods-notebooks -- find /opt/app-root/src/ -not -path '*/\.*' -not -path '/opt/app-root/src/' -exec rm -rv {} +
      Log  ${output}
  ELSE
      Fail  msg=This command requires ${admin_username} to be connected to the cluster (oc login ...)
  END


JupyterLab Is Visible
  ${jupyterlab_visible} =  Run Keyword and Return Status  Wait Until Element Is Visible  xpath:${JL_TABBAR_CONTENT_XPATH}  timeout=30
  [return]  ${jupyterlab_visible}

Wait Until JupyterLab Is Loaded
  [Arguments]   ${timeout}=60
  Wait Until Element Is Visible  xpath:${JL_TABBAR_CONTENT_XPATH}  timeout=${timeout}

Clone Git Repository
  [Arguments]  ${REPO_URL}
  Navigate Home (Root folder) In JupyterLab Sidebar File Browser
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  ${REPO_URL}
  Click Element  xpath://div[.="CLONE"]

Clone Git Repository And Open
  [Documentation]  The ${NOTEBOOK_TO_RUN} argument should be of the form /path/relative/to/jlab/root.ipynb
  [Arguments]  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  Clone Git Repository  ${REPO_URL}
  Sleep  15
  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  ${NOTEBOOK_TO_RUN}
  Click Element  xpath://div[.="Open"]

Clone Git Repository And Run
  [Documentation]  The ${NOTEBOOK_TO_RUN} argument should be of the form /path/relative/to/jlab/root.ipynb
  [Arguments]  ${REPO_URL}  ${NOTEBOOK_TO_RUN}  ${timeout}=1200
  Clone Git Repository And Open  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
  #${FILE} =  ${{${NOTEBOOK_TO_RUN}.split("/")[-1] if ${NOTEBOOK_TO_RUN}[-1]!="/" else ${NOTEBOOK_TO_RUN}.split("/")[-2]}}
  Wait Until ${{"${NOTEBOOK_TO_RUN}".split("/")[-1] if "${NOTEBOOK_TO_RUN}"[-1]!="/" else "${NOTEBOOK_TO_RUN}".split("/")[-2]}} JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active  timeout=${timeout}
  Sleep  1
  JupyterLab Code Cell Error Output Should Not Be Visible

Handle Kernel Restarts
  #This section has to be slightly reworked still. Sometimes the pop-up is not in div[8] but in div[7]

  ${kernel_or_server_restarting} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath:/html/body/div[8]/div/div[2]
  IF  ${kernel_or_server_restarting} == False
    ${is_server_down} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath:/html/body/div[8]/div/div[2]/button[2]
    IF  ${is_server_down} == False
        Click Button  xpath:/html/body/div[8]/div/div[2]/button[2]
    ELSE
        Click Button  xpath:/html/body/div[8]/div/div[2]/button
    END
  END

Run Repo and Clean
  [Arguments]  ${REPO_URL}  ${NB_NAME}
  Click Element  xpath://span[@title="/opt/app-root/src"]
  Run Keyword And Continue On Failure  Clone Git Repository And Run  ${REPO_URL}  ${NB_NAME}
  Sleep  15
  Click Element  xpath://span[@title="/opt/app-root/src"]
  Open With JupyterLab Menu  File  Close All Tabs
  Maybe Accept a JupyterLab Prompt
  Open With JupyterLab Menu  File  New  Notebook
  Sleep  5
  Maybe Select Kernel
  Sleep  5
  Add and Run JupyterLab Code Cell  !rm -rf *
  Wait Until JupyterLab Code Cell Is Not Active

Maybe Save Changes
    [Documentation]    Click the save button in a JupyterLab dialog (if one is open).
    ${dialog} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath=//div[contains(concat(' ',normalize-space(@class),' '),' jp-Dialog-content ')]
    Run Keyword If  not ${dialog}  Click Button  xpath=//div[contains(concat(' ',normalize-space(@class),' '),' jp-Dialog-content ')]/div[2]/button[3]
