# Chef_d

## Description
A one-stop shop phone application for sharing,
practicing, planning, and budgeting your meals. Users regardless of age and skill level
will be able to pick out recipes for their comfortable skill levels, whilst being able to track
and share their journey with others. A common problem with most people is that they
always end up making the same recipes and this reason in particular results in going
out to eat at restaurants because of lack of variety and simply boredom with eating the
same food over and over. Users are able to discover new recipes and expand their
cooking repertoire. Not only will the user have a vast amount of personalized and
recommended recipes from all over the world to choose from, but they will have the
ability to purchase and check out groceries within the app, which can then be delivered
to their homes or available for in-store pickup.

## Badges
TDB

## Visuals
<img src="https://cdn.discordapp.com/attachments/1071129420162670606/1177012876951687249/image.png?ex=6570f5a9&is=655e80a9&hm=6a0ad32831d424e47d373ef7223fcd8aa1fe88c17377a63e270d18468cf3fef0&" align="center" height="600" width="300"/>
<img src="https://cdn.discordapp.com/attachments/1071129420162670606/1177013087841304626/image.png?ex=6570f5db&is=655e80db&hm=f4147a580a3315ba0f0fc7e43aad06e3d4297292d55d69f3538f631d9e78dbe8&" align="center" height="600" width="300"/>
<img src="https://cdn.discordapp.com/attachments/1070406879869685923/1177013197643984936/image.png?ex=6570f5f6&is=655e80f6&hm=fe452dad170ea777530d604e1410e7f821f4f3e0bf58c35df1c6f4fce5bb815a&" align="center" height="600" width="300"/>
<img src="https://cdn.discordapp.com/attachments/1070406879869685923/1177013323682828431/image.png?ex=6570f614&is=655e8114&hm=feb60c1dc5cfbb6ea2af2aca79e3d79bdac50adc8e291fefc053e544e0f1bc14&" align="center" height="600" width="300"/>
<img src="https://cdn.discordapp.com/attachments/1070406879869685923/1177013507871485982/image.png?ex=6570f640&is=655e8140&hm=c3d633bcbc47a4aca646ce67e0227714e0f2670fdf6c880f7650c55c87fdf24f&" align="center" height="600" width="300"/>

## Installation
- Visual Studio Code
    - Dart Extension
- Flutter
- Android Studio and any Android Emulator

## Setup
1. Open Android Studio and Navigate to View -> Tool Windows -> Device Manager
2. Under Virtual, "Create Device". Hit next on any device. 
3. Select any System Image, hit Next, and then hit Finish. This will create a Virtual Device to run the Chefd application on.
4. Open VSCode, download all necessary extensions like Dart and Flutter.
5. Clone/Download Chefd Application from Gitlab Repository.
6. In terminal, run "flutter doctor" and make sure all checkboxes are green checked. Will need to 'cd' into chefd_app.
7. Bottom right corner of VSCode, select desired virtual emulator from Android Studio. 
8. Run the Chefd application (F5)


Errors when building Project
- In terminal, run "flutter clean" then "flutter pub get --no-example" 

## Usage
TBD

## Support
contact u1202975@utah.edu for support

## Contributing
This is a student project, we are not currently open to contributions

## Roadmap
Alpha Development:
- UI sketching focusing on usability
- User Registration and login for personal accounts
- Database Integration and table relation mapping
- Recipe Data scraping into the application
- Displaying User recipes


Beta Development:
- Discovery and recommedation algorithms on the home page
- Recipe creation from internal users
- Social media feed
- Interactive comment sections
- Meal planning and meal calendar functionality

Release:
- Shopping list and cart
- Grocery store API integration with Kroger


Post-Release:
- Reverse image searching for recipes
- Automated reporting system
- Smart Fridge compatibility

## Authors
- Huy Nguyen
- Jaxson Goeckeritz
- Kevin Dwyer
- Tarik Vu

## License
default copyright laws, meaning that the authors retain all rights to our source code and no one may reproduce, distribute, or create derivative works from our work

## Project status
Design phase





## Getting started

To make it easy for you to get started with GitLab, here's a list of recommended next steps.

Already a pro? Just edit this README.md and make it your own. Want to make it easy? [Use the template at the bottom](#editing-this-readme)!

## Add your files

- [ ] [Create](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file) or [upload](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#upload-a-file) files
- [ ] [Add files using the command line](https://docs.gitlab.com/ee/gitlab-basics/add-file.html#add-a-file-using-the-command-line) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://capstone-cs.eng.utah.edu/chef_d/chef_d.git
git branch -M main
git push -uf origin main
```

## Integrate with your tools

- [ ] [Set up project integrations](https://capstone-cs.eng.utah.edu/chef_d/chef_d/-/settings/integrations)

## Collaborate with your team

- [ ] [Invite team members and collaborators](https://docs.gitlab.com/ee/user/project/members/)
- [ ] [Create a new merge request](https://docs.gitlab.com/ee/user/project/merge_requests/creating_merge_requests.html)
- [ ] [Automatically close issues from merge requests](https://docs.gitlab.com/ee/user/project/issues/managing_issues.html#closing-issues-automatically)
- [ ] [Enable merge request approvals](https://docs.gitlab.com/ee/user/project/merge_requests/approvals/)
- [ ] [Automatically merge when pipeline succeeds](https://docs.gitlab.com/ee/user/project/merge_requests/merge_when_pipeline_succeeds.html)

## Test and Deploy

Use the built-in continuous integration in GitLab.

- [ ] [Get started with GitLab CI/CD](https://docs.gitlab.com/ee/ci/quick_start/index.html)
- [ ] [Analyze your code for known vulnerabilities with Static Application Security Testing(SAST)](https://docs.gitlab.com/ee/user/application_security/sast/)
- [ ] [Deploy to Kubernetes, Amazon EC2, or Amazon ECS using Auto Deploy](https://docs.gitlab.com/ee/topics/autodevops/requirements.html)
- [ ] [Use pull-based deployments for improved Kubernetes management](https://docs.gitlab.com/ee/user/clusters/agent/)
- [ ] [Set up protected environments](https://docs.gitlab.com/ee/ci/environments/protected_environments.html)

***

# Editing this README

When you're ready to make this README your own, just edit this file and use the handy template below (or feel free to structure it however you want - this is just a starting point!). Thank you to [makeareadme.com](https://www.makeareadme.com/) for this template.

## Suggestions for a good README
Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Badges
On some READMEs, you may see small images that convey metadata, such as whether or not all the tests are passing for the project. You can use Shields to add some to your README. Many services also have instructions for adding a badge.

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Installation
Within a particular ecosystem, there may be a common way of installing things, such as using Yarn, NuGet, or Homebrew. However, consider the possibility that whoever is reading your README is a novice and would like more guidance. Listing specific steps helps remove ambiguity and gets people to using your project as quickly as possible. If it only runs in a specific context like a particular programming language version or operating system or has dependencies that have to be installed manually, also add a Requirements subsection.

## Usage
Use examples liberally, and show the expected output if you can. It's helpful to have inline the smallest example of usage that you can demonstrate, while providing links to more sophisticated examples if they are too long to reasonably include in the README.

## Support
Tell people where they can go to for help. It can be any combination of an issue tracker, a chat room, an email address, etc.

## Roadmap
If you have ideas for releases in the future, it is a good idea to list them in the README.

## Contributing
State if you are open to contributions and what your requirements are for accepting them.

For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.

You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## Authors and acknowledgment
Show your appreciation to those who have contributed to the project.

## License
For open source projects, say how it is licensed.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
