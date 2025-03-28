*** Settings ***
Documentation       Tests related to upgrading MicroShift

Resource            ../../resources/common.resource
Resource            ../../resources/ostree.resource
Library             Collections

Suite Setup         Setup
Suite Teardown      Teardown

Test Tags           ostree


*** Variables ***
${USHIFT_HOST}                  ${EMPTY}
${USHIFT_USER}                  ${EMPTY}

${TOO_NEW_MICROSHIFT_REF}       ${EMPTY}

${EXPECTED_LOG}                 Current active deployment ID and deployment ID
...                             in version file are the same - not restoring,
...                             continuing startup with current data.


*** Test Cases ***
Upgrading MicroShift By Two Minor Versions Is Blocked
    [Documentation]    Test verifies if attempt to upgrade MicroShift
    ...    by two minor versions is blocked.

    Wait Until Greenboot Health Check Exited
    ${initial_deploy_backup}=    Get Future Backup Name For Current Boot

    Deploy Commit Expecting A Rollback    ${TOO_NEW_MICROSHIFT_REF}

    Wait Until Greenboot Health Check Exited
    Backup Should Exist    ${initial_deploy_backup}
    Journal Should Have Information About Failed Version Comparison
    Journal Should Have Information That MicroShift Skipped Restoring


*** Keywords ***
Setup
    [Documentation]    Test suite setup
    Check Required Env Variables
    Should Not Be Empty    ${TOO_NEW_MICROSHIFT_REF}    TOO_NEW_MICROSHIFT_REF variable is required
    Login MicroShift Host

Teardown
    [Documentation]    Test suite teardown
    Logout MicroShift Host

Journal Should Have Information That MicroShift Skipped Restoring
    [Documentation]    TODO

    ${stdout}    ${rc}=    Execute Command
    ...    journalctl --unit=microshift --grep "Starting restore" --case-sensitive=true
    ...    sudo=True
    ...    return_stdout=True
    ...    return_rc=True

    # String should not be found
    Should Be Equal As Integers    1    ${rc}

    ${version}=    MicroShift Version
    IF    ${version.minor} == 13    RETURN

    ${stdout}    ${rc}=    Execute Command
    ...    journalctl --unit=microshift --grep "${EXPECTED_LOG}" --case-sensitive=true
    ...    sudo=True
    ...    return_stdout=True
    ...    return_rc=True

    Log Many    ${stdout}    ${rc}
    Should Be Equal As Integers    0    ${rc}
