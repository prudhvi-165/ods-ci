*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library          JupyterLibrary
Suite Teardown   End Web Test
Force Tags       JupyterHub


*** Variables ***
${DEFAULT_CULLER_TIMEOUT} =    xyz
${CUSTOM_CULLER_TIMEOUT} =     600


*** Test Cases ***
Verify Default Culler Timeout
    [Documentation]    Checks default culler timeout
    [Tags]  Sanity
    ${current_timeout} =  Get Culler Timeout
    Should Be Equal  ${DEFAULT_CULLER_TIMEOUT}  ${current_timeout}

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]  Sanity
    ...     Resources-GPU
    ...     ODS-1142
    # Modify Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    # Try out invalid timeouts? 
    # Verify UI default == configmap default?
    ${current_timeout} =  Get Culler Timeout
    Should Not Be Equal  ${current_timeout}  ${DEFAULT_CULLER_TIMEOUT}
    Should Be Equal   ${current_timeout}  ${CUSTOM_CULLER_TIMEOUT}
    # Run  oc exec ${CULLER_POD} -n redhat-ods-applications -- printenv CULLER_TIMEOUT

Verify Culler Kills Inactive Server
    [Documentation]    Verifies that the culler kills an inactive 
    ...    server after timeout has passed.
    [Tags]  Sanity
    Spawn Minimal Image
    Run Cell And Check Output  print("Hello World")  Hello World
    Open With JupyterLab Menu    File    Save
    Close Browser
    Sleep    ${CUSTOM_CULLER_TIMEOUT}+60
    # Verify User Pod Is Not Running
    # Verify Culler Logs ?
    # [I 220331 15:02:13 __init__:191] Culling server ${username} (inactive for 00:02:09)
    #    ^date  ^timestamp                            ^not jh naming            ^strictly greater than ${CUSTOM_CULLER_TIMEOUT}
    # from datetime import timedelta;td=timedelta(seconds=${CUSTOM_CULLER_TIMEOUT});print(td) -> gets timeout in hh:mm:ss
    # grep from log -> td2 = timedelta(hours=HH, minutes=MM, seconds=SS); td2>td 

Verify Culler Does Not Kill Active Server
    [Documentation]    Verifies that the culler does not kill an active 
    ...    server even after timeout has passed.
    [Tags]  Sanity
    Spawn Minimal Image
    Add and Run JupyterLab Code Cell in Active Notebook    import time;print("Hello");time.sleep(${CUSTOM_CULLER_TIMEOUT}*2);print("Goodbye")
    Open With JupyterLab Menu    File    Save
    Close Browser
    Sleep    ${CUSTOM_CULLER_TIMEOUT}+60
    # Verify User Pod Is Running
    # Verify Culler Logs ?

# Verify Do Not Stop Idle Notebooks
    # Unclear what this UI option will do

*** Keywords ***
Spawn Minimal Image
    [Documentation]    Spawn a minimal image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook  size=Default

Get Culler Timeout
    [Documentation]    Gets the current culler timeout
    ${current_timeout} =  Run  oc describe configmap jupyterhub-cfg -n redhat-ods-applications | grep -zoP '(culler_timeout:\n----\n)\d+\n' | grep -zoP "\d+"
    [Return]  ${current_timeout}
