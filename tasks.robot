*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Salesforce
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
#${CsvUrl}    https://robotsparebinindustries.com/orders.csv
${TEMP_OUTPUT_DIRECTORY}    ${CURDIR}${/}temp
${PDF_OUTPUT_DIR}           ${CURDIR}${/}pdf


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up directories
    Download File
    Open the robot order website
    ${OrderDt}    Read table from CSV    path=orders.csv    header=True
    FOR    ${OrderNum}    IN    @{OrderDt}
        Initial click
        Fill the form    ${OrderNum}
        Preview the robot
        Submit the order
        ${Pdf}    Store the receipt as a PDF file    ${OrderNum}[Order number]
        ${screenShot}    Take a screenshot of the robot    ${OrderNum}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenShot}    ${Pdf}
        Click Button    id:order-another
    END
    Create a ZIP file of the receipts
    Close Browser
    Log    Done.


*** Keywords ***
Download File
    Add text input    name=url    label=input URL
    ${CsvUrl}    Run dialog
    Download    ${CsvUrl.url}    overwrite= True

Open the robot order website
    ${Credential}    Get Secret    credential
    Open Available Browser    url=${Credential}[UrlSite]
    #Open Available Browser    url=https://robotsparebinindustries.com/#/robot-order

Initial click
    Click Button    OK

Fill the form
    [Arguments]    ${OrderNum}
    Select From List By Index    head    ${OrderNum}[Head]
    Select Radio Button    body    ${OrderNum}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${OrderNum}[Legs]
    Input Text    address    ${OrderNum}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    ${ClickAvailable}    Is Element Visible    id:order-completion
    WHILE    ${ClickAvailable} is False
        Click Button    id:order
        ${ClickAvailable}    Is Element Visible    id:order-completion
    END

Store the receipt as a PDF file
    [Arguments]    ${OrderNum}
    Wait Until Element Is Visible    id:order-completion
    ${orderResult}    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${orderResult}    ${PDF_OUTPUT_DIR}${/}${OrderNum}.pdf
    RETURN    ${PDF_OUTPUT_DIR}${/}${OrderNum}.pdf

Take a screenshot of the robot
    [Arguments]    ${OrderNum}
    Screenshot    id:robot-preview-image    ${TEMP_OUTPUT_DIRECTORY}${/}${OrderNum}.png
    RETURN    ${TEMP_OUTPUT_DIRECTORY}${/}${OrderNum}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${Scrennshot}    ${Pdf}
    ${PdfContent}    Create List    ${Scrennshot}
    Add Files To Pdf    ${PdfContent}    ${Pdf}    append=True

Set up directories
    Create Directory    ${TEMP_OUTPUT_DIRECTORY}
    Create Directory    ${PDF_OUTPUT_DIR}
    Create Directory    ${OUTPUT_DIR}

Create a ZIP file of the receipts
    ${zip_file_name}    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${PDF_OUTPUT_DIR}    ${zip_file_name}
