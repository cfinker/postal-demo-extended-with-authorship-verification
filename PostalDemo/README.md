# Mail app with AI based on Postal framework

This repo contains the iOS mail app (Diplay Name: Mail Authorship Verification) developed with the [Postal](https://github.com/snipsco/Postal  "Postal") framework for
reasearch on AI (authorship verification and phishing recognition). It will use
[uClassify](https://uclassify.com "uClassify") and [Core ML 3](https://developer.apple.com/documentation/coreml "Core ML 3") for the AI part.

## How to setup?
Please have a look for the setup description in the [README.md](https://github.com/cfinker/postal-demo-extended-with-authorship-verification/tree/master/README.md "README.md") file in root folder of this repo. There you will find all needed details. Short version: Just open the Xcode porject of this folder and then a build should be able, even thought some warnings/errors will occure upon opening the project in Xcode.

Remark: Do NOT run any carthage updates or try to update any dependencies. Since Postal framework changed a lot in the last few months a update of the project dependencies will cause build errors and need some fixes in order to get the project running again.

## uClassify API keys and user
The uClassify user and API keys can be set in the Info tab of the PostalDemo XCode project (Custom iOS Target Properties).

* UCLASSIFY\_READ_KEY
* UCLASSIFY\_WRITE_KEY
* UCLASSIFY\_USER_API

## Mail not working?
Please keep always in mind, that this project is only a prototype for answering scenctific questions. Therefore, not all mail providers have been tested. I always used a Gmail account, but there I had to deactive some security settings, to allow 'unsecure' applikation to login with e-mail address and password. Unfortunalty, the error messages of Postal are also sometimes not very helpful (this aspect cost a lot of time in the begin of the project).

## Planned features

*  Add one single mail account, save credientails in keychain
*  Receive all mails via IMAP and show in one single list 
*  Each mail can be viewed in detail, with its content as plain text
*  Send all already received mails per click to classifiers and create/train models by a single click
*  Send data to classifieres and show results in mail detail view

## Contact
Devloped by Christian Finker, IMS18
Website: christianfinker.eu