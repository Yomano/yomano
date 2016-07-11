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

For this to work you should have the package `yomano-angular-example` installed as global or placed in you yomano home path.

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

Go to an empty folder named as `yonamo-<something>`, execute `yomano new` and answer the questions.

You should have now a `index.js`, `license`, `package.json` files and a `source` folder.

Put your template files inside the source folder. Rename then as bellow and insert the template tags.

Edit `index.js` as needed (in many cases you don't even need), and you are done.

### index.js

The only mandatory entries are `name` and `description`.

Also, notice you have `chalk` available so you can easily print out nice colored texts.  

```js
module.exports = function(chalk){
    return {
        name: 'something',
        description: 'something pack.\n'+chalk.gray("I'm awesome!"),
        prompt: [
            {name:'test', type:'boolean'},
        ],
        special: [
            ['optional/*', 'if:test']
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

An array of objects. Used to inquire the user with relevant questions. You can use all features of [prompt](https://www.npmjs.com/package/prompt) package, as long you use its *alternate validation api*.

The first 3 questions are standard:

- application name
- user name
- user email

### special

For special cases you have the `special` array.

It should be an array of arrays, the second array has two strings.

The first strings is a file name which could use wildcards. The second string is a list (separated by **;**), of commands to apply to that file.

There is two commands:

- `if` - this filters the files by checking responses to the prompt.
- `final` - this says to **not** preprocess this files while copying it.

You can use `if:test` for a positive test or `if:!test` for a negative.

In example above the content of `optional` folder is only installed if you answer true for the *test* question when prompted.

### file names

You can change file names to match your needs by naming files inside `source` folder as `{name}.js` or even `.{name}-config.ini`

Yomano will rename then to `something.js` and `.something-config.ini` if you answer `something` for your application's name.

### preprocessor

Yomano uses [preprocess](https://github.com/jsoverson/preprocess#directive-syntax) as it template engine. You can use any of its directives as long you **ALWAYS** use the `js` syntax, no matter the file you are producing. All used directive will be removed after its evaluation so your final code will be fine.

Example in a js file:

```js
var user = "/* @echo owner */";

/* @if test==true */
test = require('test');
test.doit(user);
/* @endif */
```

in HTML:

```html
<label for="email">Email</label>
<input type="text" name="f_email" id="email" value="/* @echo email */">
```

JSON

```json
{
    "who": "/* @echo owner */"
    /* @if test==false */
    ,
    "disable_test": true
    /* @endif */
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

There is 5 callbacks you can use:

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
