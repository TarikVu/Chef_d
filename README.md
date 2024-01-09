# Chef_d
Originally developed as a Senior Capstone Design I & II project at the University of Utah's School of Computing,  Chef'd is a cooking application aimed to provide users with a means to discover, order, plan, and share recipes all in one place. The recipe's found on our application are either scraped from websites with a [scraper](https://github.com/hhursev/recipe-scrapers) publicly available on Github, or created by fellow users.
More details to be found at our [website here](https://chefd.framer.ai/).

## Table of Contents
1. [Application Features](#features)
2. [System Architecture & Technologies](#arch_tech)
3. [Setup](#setup)
4. [Developers](#devs)

## <a name="features"></a>Application Features
![chefd1](https://media.discordapp.net/attachments/1194092179673579540/1194095150654300301/ChefdPreview1.PNG)
- Users are able to create an account with Chef'd.  The verification process is carried out by the Supabase.
- Upon loggin in users are greeted with a Discover page of the latest recipes our application provides (scraped or created by users internally).
- Viewing a recipe displays the ingredients, nutrition facts, & reviews left by other users.
  
![chefd2](https://media.discordapp.net/attachments/1194092179673579540/1194095150968881282/ChefdPreview2.PNG)
- Chef'd also offers users an integrated social media platform.  Sharing your food adventure is as simple as tapping on "Create a Post" inside our app!
- Users can import the ingredients for a recipe found on the discover page to their shopping cart.  By providing their zip code, A Kroger API call is made to find participating grocery stores in that area.  Then the shopping cart is forwarded to Kroger and the user is redirected to their website for pickup and delivery.
- With the meal pantry and meal planning features, users can set meals for themselves weeks or months in advance.
  
## <a name="arch_tech"></a>System Architecture & Technologies
![architecture](https://media.discordapp.net/attachments/1194092179673579540/1194099418639642756/Arch.png)

### Technologies utilized:
Dart, Flutter, Supabase (Database)

## <a name="setup"></a>Setup
### See the following in-depth guide on our [official website here.](https://chefd.framer.ai/DownloadAndUsage)

## <a name="roadmap"></a>Roadmap
### Alpha Development:
- UI sketching focusing on usability
- User Registration and login for personal accounts
- Database Integration and table relation mapping
- Recipe Data scraping into the application
- Displaying User recipes


### Beta Development:
- Discovery and recommedation algorithms on the home page
- Recipe creation from internal users
- Social media feed
- Interactive comment sections
- Meal planning and meal calendar functionality

### Release:
- Shopping list and cart
- Grocery store API integration with Kroger

## <a name="devs"></a>Developers
![devTeam](https://media.discordapp.net/attachments/1194092179673579540/1194112956804366396/team.jpg)
From left to right:
- Jaxson Goeckeritz
- Huy Nguyen
- Tarik Vu
- Kevin Dwyer

## License
default copyright laws, meaning that the authors retain all rights to our source code and no one may reproduce, distribute, or create derivative works from our work.

## References
### [Scraper](https://github.com/hhursev/recipe-scrapers)
