# iOS mail (prototype) app with AI based on Postal framework

This project is a prototpye of an iOS mail client which uses machine learning (uClassify and Core ML 3) for authorship verification. The whole project is based on the framework Postal.

## Repo structure

Since the further developement of iOS as well as the Postal framework, which have been not always in sync, this repo contain the Postal source code (at the state of Februrary 2019) as well as the extended Postal-Demo app, which is my prototype. This prototype is not working without any issues whith the currently state of the Postal's master branch. This is the reason why the Postal source code is in this repo too.

All folder and files on the root level are Postal folders and files. Basically also the PostalDemo folder was once a original Postal folder, but I extended this folder with some files and folders in order to create my mail authorship verification prototpye.

## How to run the prototpye or to open its source code?
If you want to run or have a closer look on the prototype, you should go into the PostalDemo folder on open the [PostalDemo.xcodeproj](https://github.com/cfinker/postal-demo-extended-with-authorship-verification/tree/master/PostalDemo/PostalDemo.xcodeproj "PostalDemo.xcodeproj") file with xCode (at least xCode 11 and at least macOS 10.14). Since all dependencies are as well part of this repo (namely its the Postal framework), the project should build and run in xCode without any fruther required commands. It could be that xCode does not recognize on start up that all source code has been translated to Swift 5 and that it will display some warning. You can ignore this warning, and once the index of xCode has finished, it will recognize that there is no reason to warn. 

## What machine learning is used?
The app uses Core ML 3. Therefore iOS 13 is required (for on-device training).
It uses uClassify as well, with a daily limit of max. 500 requests per day.

## Further information and contact
This project is supported by netidee: 
https://www.netidee.at/mail-authorship-verification-and-phishing-recognizing-machine-learning-ios

As soon as my master thesis is finished, some more details of the usage of this prototype, can be found on the netidee-website. The master thesis with all evaluation results and interessting implementation details will be published there.

Developer: Christian Finker, IMS18, FH Joannuem (IT- and Mobile Security); Website of developer: https://webrabbit.at

### Links to used frameworks and web services
Postal: https://github.com/snipsco/Postal and uClassify: http://uclassify.com
