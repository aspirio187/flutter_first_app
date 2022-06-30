# flutter_first_app

Simple form with textfield, datetime picker and 2 dropdown menus one for movies genres loaded on creation and the second one with movies from the genre selected in the first dropdow.

For the app to work, you must follow these steps :

### 1. Create an account on https://www.themoviedb.org/login

Once you've created your account, activate it and login.

### 2. Retrieve your API KEY on https://www.themoviedb.org/settings/api

Get an API Key and copy it to your clipboard

### 3. Choose the platform on which you want to run the app

In VSCode, you can choose the platform with the button on the lower right of the window or you can run the following terminal command :

* First go to your project's root folder
* Run the next command `flutter create --platforms=[YOUR_PLATFORM] .`

**Don't forget the '.' at the end to specify the projet**

If you want to run the app on linux, just tip `flutter create --platforms=linux .`

### 4. Save the API Key as a environment variable with the name `TMDB_API_KEY`

Voilà, it should work just fine.
