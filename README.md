# Yomano

Do you know [Yeoman](yeoman.io)? Well Yomano does the same! :smile:

Well, almost! Yomano is far behind Yeoman when you think about flexibility and capabilities, but for simple projects Yomano has a far simpler workflow in creating a new template package. You don't even have to write code as in Yeoman, but you can if you have to. 

## Install

It should be installed as global.

```bash
npm install -g yomano
# or
yarn global add yomano
```

## Setting up a new project

```bash
yomano setup angular-example
```

For this to work you should have the package `yomano-angular-example` installed as global or placed in your yomano home path.

## Home path

You can set any local path to hold your yomano templates. This is an easy way to create personal private templates.

```bash
# set
yomano home /home/user/.hide/my-yomanos
# get
yomano home
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

You should have now a `index.js`, `license` and `package.json` files and a `source` folder.

Put your template files inside the source folder. Rename them as bellow and insert template tags.

Edit `index.js` as needed (in many cases you don't even have to), and you are done.

You are ready to setup a new project using this template with: `yomano setup something`.

### index.js

The only mandatory entries are `name` and `description`.

Notice you have `chalk` available so you can easily print out nice colored texts. You also have `fs` and `path` in case you want to deal with files yourself. Also you can use `gulp` to create tasks to be used inside your project.

```js
module.exports = function(chalk, fs, path, gulp){

    gulp.task('default', ['build'], function(cb){
        console.log('running default');
        cb();
    });

    gulp.task('task1', function(cb){
        console.log('running task 1');
        cb();
    });

    return {
        name: 'something',
        description: 'something pack.\n'+chalk.gray("I'm awesome!"),
        prompt: [
            {name:'extra', message:'Install extra pack?', type:'confirm', default:false},
        ],
        init         : function(){},
        after_prompt : function(context){},
        before_copy  : function(context){},
        after_copy   : function(context){},
        say_bye      : function(context){},
        tasks: [],
    }
}
```

### prompt

An array of objects. Used to inquire the user with relevant questions. You can use all features of [inquirer](https://www.npmjs.com/package/inquirer) package.

The first 4 questions are standard:

- application name
- destination directory (defaults to `home` when creating new yomanos)
- user name
- user email

### file names

You can rename file names to match your needs by naming files inside `source` folder as `{name}.js` or even `.{name}-config.ini`.

Yomano will rename them to `something.js` and `.something-config.ini` if you answer `something` for your application's name.

Also, yomano will create empty folders for you, but git will not track them. So, you can create a `.yomanoignore` file inside it and you will have your desired tracked empty folder.

You can select what to copy by the way you name your files. To do so, you should name a file like: `(+extra)file.ext`, in this case the file `file.ext` will be installed only if you answer *yes* to the question of previous example. 

Want something more complex? What about: `(+mode)(-private)file-{name}.js`? Here the file `file-something.js` will be installed if you answer *yes* to mode **and** *no* to private. 

A simple example:

```js
// this is your index.js
module.exports = function(chalk, fs, path, gulp){
    return {
        prompt: [
            {name:'mode', message:'Use advanced mode? [yes]', type:'confirm', default:true},
        ],
    }
}
```

and name your files as:

```bash
www/(+mode)index.html    # this will be the advanced
www/(-mode)index.html    # and this the normal
```

here we have a single folder with multiple files inside for each mode. But you might prefer select between two folders:

```bash
(+mode)www/index.html    # this will be the advanced
(-mode)www/index.html    # and this the normal
```

Finally, if you have a `.ejs` file (or any other type of file which contains ejs tags), that you don´t want yomano to render, then you should name it as `(!final)myTemplate.ejs`.

### preprocessor

Yomano uses [ejs](https://github.com/mde/ejs#ejs) as its template engine. You can use any of its directives. All used directive will be removed after its evaluation so your final code will be fine.

Example in a js file:

```js
var user = "<%= owner %>";

%%% if(test){
test = require(<%- pack_name %>);
test.doit(user);
%%% }
```

in HTML:

```html
<input type="text" name="f_email" id="email" value="<%= email %>">
```

JSON (you have lots of syntax errors, but the final file should be fine!)

```json
{
    <%_ if(!test) { -%>
    "disable_test": false,
    <%_ } -%>
    "who": "<%= owner %>"
%%% if(test){
    ,"disable_test": true
%%% }
}
```

For non echo block you can use the standard ejs notation `<%` and `<%_` and also the `%%%` notation, as long it starts on first column of text.

### context and callbacks

Context is an object passed to callbacks.

The following properties are available at `init` callback:

- `context.platform`
- `context.source`
- `context.date`
- `context.dest` (original value)
- `context.filters`

These are available for `after_prompt`:

- `context.name`
- `context.owner`
- `context.email`
- `context.dest` (updated value)

also any other information you have requested in your prompts will be available in context (like `context.mode` in previous example).

All remaining callbacks will also include:

- `context.files`

There are 5 callbacks you can use:

- **init** - can be used to print something to the user.
- **after_prompt** - `context.filter` will match all, here you have a chance to make changes to it.
- **before_copy** - `context.files` have an array of all files to be copied, and you can hack with it.
- **after_copy** - the copy is done. You can start an environment here, for example, you can execute `bower install && npm install` at this point.
- **say_bye** - last opportunity to print a message or something like that.

Callbacks can execute any code and print to console with `console.log`, also you can return an array with strings. Any string will be executed by your system´s shell.

example of a python project:

```js
after_copy : function(context){
    console.log(chalk.yellow('\nPreparing your environment, that may take a long time...\n'))
    return [
        'virtualenv venv',
        ((context.platform=='win32')? 'venv\\scripts\\activate':'venv/bin/activate') + ' && pip install -r requirements.txt',
    ]
}
```

## Tasks

Once you have a project started with yomano you can use yomano tasks to deal with it.

A task is declared using the same structure of a base yomano´s pack but can only be started from inside a previously created yomano project.

Example of a project with a yomano task and also a gulp task:

```js
module.exports = function(chalk, fs, path, gulp){

    gulp.task('task1', function(cb){
        console.log('running gulp task');
        cb();
    });

    return {
        name: 'project',
        description: 'Yomano´s project',
        prompt: [],
        tasks: [
            {
                name: 'task2',
                description: 'project task',
                prompt: [
                    {name:'name', message:'Function name'},
                ],
                init         : function(){},
                after_prompt : function(context){},
                before_copy  : function(context){},
                after_copy   : function(context){},
                say_bye      : function(context){},
            },
        ],
    }
}
```

Once you start this project with `yomano setup project` you will be presented the information you have `task1` and `task2` available in your project.

From have inside your project tree you can issue the command `yomano task` to list all available tasks and `yomano task task1` to execute the task.

If you execute a gulp then it will run as a regular gulpfile.js from the root of your project.

If you execute a yomano´s task then their prompt will be executed and files from `tasks/task2` folder will be copied following the same rules the original `setup` command follows (except it copy files from `task/TASK_NAME` instead of `source`). the same callbacks are available too. The only limitation is that you can´t nest tasks inside tasks.

## Publish

If you want to share your template simple execute `npm publish` from inside your pack folder. 

Then any one can install it with: `npm install -g yomano-your-pack-name`

## Yomano?

It's a joke name. The name is close to the original Yeoman. Besides, in Portuguese, Yomano sounds like *Yo-bro*, in English. Am I a kid? No, why? 

Another thing, that makes me sad, is that when I started to look for a place to promote Yomano I found [Yoga](https://github.com/raineorshine/generator-yoga)! It's a Yeoman generator but the idea behind it is **too much** close to the ideas I had to Yomano. It uses ejs templates and weird file names to control installation too. If I knew about it before, I could have saved the time that took me to create Yomano. Check it out.

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

# build code with:
npm run build
# or, to watch for changes
npm run dev
```
