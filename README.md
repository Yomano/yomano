# Yomano

Do you know [Yeoman](yeoman.io)? Well Yomano does the same! :smile:

Liar! Yomano is far behind Yeoman when you think about flexibility and capabilities, but for simple projects Yomano has a far simpler workflow in creating a new template package. You don't even have to write code as in Yeoman, but you can if you have to. 

## Install

It should be installed as global.

```bash
npm install -g yomano
```

## Setting up a new project

```bash
yomano setup angular-example
```

For this to work you should have the package `yomano-angular-example` installed as global or placed in your yomano home path.

## Home path

You can set any local path to hold your yomano templates. This is an easy way to create personal private templates.

```bash
#get
yomano home
#set
yomano home /home/user/.hide/my-yomanos
```

Inside your home path you should have your yomano template folders side-by-side, like:

```bash
/home/user/.hide/my-yomanos$ ls
yomano-node-project
yomano-angular
yomano-something
```

## Creating a new template pack

Go to an empty folder named as `yonamo-something`, execute `yomano new` and answer the questions.

You should have now a `index.js`, `license`, `package.json` files and a `source` folder.

Put your template files inside the source folder. Rename then as bellow and insert the template tags.

Edit `index.js` as needed (in many cases you don't even need), and you are done.

You are ready to setup a new project with this template with: `yomano setup something`.

### index.js

The only mandatory entries are `name` and `description`.

Notice you have `chalk` available so you can easily print out nice colored texts. You also have `js` and `path` in case you want to deal with files yourself.

```js
module.exports = function(chalk, fs, path){
    return {
        name: 'something',
        description: 'something pack.\n'+chalk.gray("I'm awesome!"),
        prompt: [
            {name:'extra', message:'Install extra pack?', type:'confirm', default:false},
        ],
        special: [
            ['optional/*', 'if:extra']
        ],
        init         : function(){},
        after_prompt : function(context){},
        before_copy  : function(context){},
        after_copy   : function(context){},
        say_bye      : function(context){},
    }
}
```

### prompt

An array of objects. Used to inquire the user with relevant questions. You can use all features of [inquirer](https://www.npmjs.com/package/inquirer) package.

The first 3 questions are standard:

- application name
- user name
- user email

### special

For special cases you have the `special` array.

It should be an array of arrays, the second array has two strings.

The first strings is a file name which could use wildcards. The second string is a list (separated by **;**), of commands to apply to that file.

There are 3 commands:

- `if` - this filters the files by checking responses to the prompt.
- `final` - this says to **not** preprocess this files while copying it.
- `rename` - can rename parts of your relative file path.

You can use `if:test` for a positive test or `if:!test` for a negative.

In example above the content of `optional` folder is only installed if you answer true for the *test* question when prompted.

A special like: `['temp1/robot.txt', 'rename:temp1:www']` will save the file from `<context.source>/temp1/robot.txt` as `<context.dest>/www/robot.txt`.

You can combine all together:

```js
return {
    prompt: [
        {name:'mode', message:'Use advanced mode? [yes]', type:'confirm', default:true},
    ],
    special: [
        ['advanced/index.html', 'if:mode;rename:advanced:www'],
        ['normal/index.html', 'if:!mode;rename:normal:www'],
    ],
}
```

This example is fine, but in many cases is easier to have a single index.html and use preprocess directives inspecting `context.mode` inside it to change as needed.


### file names

You can change file names to match your needs by naming files inside `source` folder as `{name}.js` or even `.{name}-config.ini`

Yomano will rename then to `something.js` and `.something-config.ini` if you answer `something` for your application's name.

Also, yomano will create empty folders for you, but git will not track then. So, you can create a `.yomanoignore` file inside it and you will have your desired tracked empty folder.

### preprocessor

Yomano uses [ejs](https://www.npmjs.com/package/ejs) as its template engine. You can use any of its directives. All used directive will be removed after its evaluation so your final code will be fine.

Example in a js file:

```js
var user = "<%= owner %>";

<%_ if(test){ %>
test = require('test');
test.doit(user);
<%_ } %>
```

in HTML:

```html
<input type="text" name="f_email" id="email" value="<%= email %>">
```

JSON (you have lots of syntax errors, but the final file should be fine!)

```json
{
    "who": "<%= owner %>"
    <%_ if(test){ %>
    ,
    "disable_test": true
    <%_ } %>
}
```

### context and callbacks

Context is an object passed to callbacks. The first callback (`init`), does not receive a context.

These are available for `after_prompt`:

- `context.platform`
- `context.source`
- `context.dest`
- `context.date`
- `context.filters`
- `context.name`
- `context.owner`
- `context.email`

also any other information you have requested in your pack will be available in context (like `context.test` in current example).

All remaining callbacks will also include:

- `context.files`

There are 5 callbacks you can use:

- **init** - can be used to print something to the user.
- **after_prompt** - `context.filter` will be populated with your special filters applied, here you have a chance to make changes to it.
- **before_copy** - now you have an array of all files to be copied, and you can hack with it.
- **after_copy** - the copy is done. You can start an environment here, for example, you can execute `bower install && npm install` at this point.
- **say_bye** - print a last opportunity message or something like that.

Callbacks can execute any code and print to console with `console.log`, also you can return an array with strings and functions. Any string will be executed by your shell. Functions are executed in its turn.

example of a python project:

```js
after_copy : function(context){
    console.log(chalk.yellow('\nPreparing your environment, may take a long time...\n'))
    return [
        'virtualenv venv',
        function(){console.log('I could be an echo :)');},
        ((context.platform=='win32')? 'venv\\scripts\\activate':'venv/bin/activate') + ' && pip install -r requirements.txt',
    ]
}
```

## Publish

If you want to share your template simple execute `npm publish` from inside your pack folder. 

Then any one can install it with: `npm install -g yomano-your-pack-name`

## Yomano?

It's a joke name. The name is close to the original Yeoman. Besides, in Portuguese, Yomano sounds like *Yo-bro*, in English. Am I a kid? No, why? 

## Developing

If you want to change the code:

```bash
# clone it to a local folder
git clone git@github.com:Yomano/yomano.git

# install dependencies
npm install -g coffeescript
npm install

# install in dev mode
npm link

# compile code with:
npm run compile
# or
npm run watch
```
