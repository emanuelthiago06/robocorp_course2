*** Settings ***
Documentation        Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.PDF
Library    RPA.Tables
Library    Collections
Library    RPA.Robocloud.Secrets
Library    RPA.Archive





*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Get orders
    ${orderid}=    Open and save worksheet
    Create a Zip File    ORDER_NUMBER=${order_id}


Minimal task
    Log    Done.


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying popup
    Set Local Variable              ${btn_yep}        //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button           ${btn_yep}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv   

Open and save worksheet
     ${orders}=  Read table from CSV    orders.csv
     FOR    ${order}    IN    @{orders}
        Close the annoying popup
        Fill and submit the form for one person    ${order}
    END
    
Fill and submit the form for one person
    [Arguments]    ${order}
    Wait Until Element Is Visible    head
    Select From List By Value    head    ${order}[Head]
    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Wait Until Keyword Succeeds     10x     2s    Preview the robot
    Wait Until Keyword Succeeds     10x     2s    submit the order
    ${orderid}  ${img_filename}=    Take screenshot
    ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
    Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
    go for the next form
    [Return]    ${order_id}

Preview the robot
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]

Submit the order
    Click button                    //*[@id="order"]
    Page Should Contain Element     //*[@id="receipt"]


Take screenshot
    Set Local Variable      ${lbl_orderid}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable      ${img_robot}        //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid}

    ${orderid}=                     Get Text            //*[@id="receipt"]/p[1]
    Set Local Variable              ${fully_qualified_img_filename}    ${CURDIR}${/}image_files${/}${orderid}.png
    Sleep   1sec
    Log To Console                  Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}
    [Return]    ${orderid}  ${fully_qualified_img_filename}

Store the receipt as a PDF file
    [Arguments]        ${ORDER_NUMBER}

    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${CURDIR}${/}pdf_files${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}
    Open PDF        ${PDF_FILE}
    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}

go for the next form
    Set Local Variable      ${btn_order_another_robot}      //*[@id="order-another"]
    Click Button            ${btn_order_another_robot}

Create a Zip File
    [Arguments]    ${ORDER_NUMBER}    
    Archive Folder With ZIP     ${CURDIR}${/}pdf_files    ${CURDIR}${/}output${/}pdf_zipped.zip   recursive=True  include=*.pdf