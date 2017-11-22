chalk      = require 'chalk'
ejs        = require 'ejs'
{execSync} = require 'child_process'
fs         = require 'fs'
globby     = require 'globby'
inquirer   = require 'inquirer'
jsesc      = require 'jsesc'
minimatch  = require 'minimatch'
mkdirp     = require 'mkdirp'
Progress   = require 'progress'
path       = require 'path'
commander  = new (require('commander').Command)('yomano')


pack = null
config = null
context =
    platform : process.platform
    dest     : process.cwd()
    filters  : ['**/*']
    date:
        year: new Date().getFullYear()


### Manage our configuration file
on linux its saved at: ~/.yomanorc in JSON format
###
class MyConfig
    constructor: (name=path.basename(__filename)) ->
        @configFile = path.join (process.env.HOME || process.env.USERPROFILE), ".#{name.split('.')[0]}rc"
        try
            @data = JSON.parse fs.readFileSync @configFile
        catch
            @data = {}

    get: (id) -> @data[id]
    set: (id, val) ->
        @data[id] = val
        fs.writeFileSync @configFile, JSON.stringify @data, null, 4

### process the command line
###
processCli = ->
    commander
        .version require('../package.json').version

    commander
        .command 'setup <pack_name>'
        .description 'setup a new environment'
        .option '-s, --save', 'save personal information'
        .option '-f, --force', 'force instalation into non empty folder'
        .option '-v, --verbose', 'verbose mode'
        .action (pack, options) ->
            context._verbose  = options.verbose
            context._save     = options.save
            context._force    = options.force
            context.pack_name = pack
            context.pack_file = "yomano-#{pack}"

    commander
        .command 'list'
        .alias 'ls'
        .description 'List all available yomano packs'
        .action () ->
            console.log "\nList of available packs in your system (global + yomano home)\n"
            prefix = execSync('npm -g root').toString()[..-2]
            for p in globby.sync [path.join(config.get('home'), 'yomano-*'), path.join(prefix, 'yomano-*')]
                id = /yomano-([a-zA-Z0-9-]+)$/.exec p
                try
                    ver = require(path.join p, 'package.json').version
                    console.log chalk.cyan(id[1]), chalk.gray "@#{ver}"
                catch
                    console.log chalk.red id[1]
            process.exit 0

    commander
        .command 'new'
        .description 'start a new pack for yomano'
        .option '-v, --verbose', 'verbose mode'
        .action (options) ->
            context._verbose  = options.verbose
            context.pack_name = 'new'
            context.pack_file = "../yomano-yomano"
            context.dest = config.get('home') || context.dest

    commander
        .command 'task <task_name>'
        .description 'execute a task on a yomano project'
        .action (task, options) ->
            console.log '\n\nto be implemented\n'
            process.exit 1

    commander
        .command 'home [home]'
        .description 'get/set personal home folder'
        .action (home) ->
            config.set 'home', path.resolve home if home?
            console.log "\nYour current home folder: #{chalk.yellow config.get 'home'}"
            process.exit 0

    commander.parse process.argv

    commander.help() unless context.pack_name?

### render template files with ejs
###
render = (input, data = {}, options = {}) ->

    options.escape = (input) -> jsesc input, {quotes:'double'}

    template = input.replace /^%%%\s*(.+)\s*$/gm, (m, m1) -> "<\%_ #{m1} -\%>"

    try
        ejs.render template, data, options
    catch e
        console.error e
        process.exit 1

### copy a file while rendering its content if applicable
###
copyFile = (source, target, context, final, cb) ->
    cbCalled = no

    done = (err) ->
        unless cbCalled
            cb? err
            cbCalled = yes

    return done() if minimatch source, '.yomanoignore', {matchBase:true, dot:true}

    console.log target if context._verbose

    if target[-1..] in '/\\'
        mkdirp target, (err) -> done err
    else
        mkdirp path.dirname(target), (err) ->
            return done err if err

            fs.readFile source, (err, data) ->
                data = render data.toString(), context unless final
                fs.writeFile target, data, (err) -> done err

### execute events
if event returns an array each string item will be executed in current shell. if item is
a function it will be executed and its output will be treated like the original one.
###
executeEvents = (fn, context) ->
    new Promise (resolve, reject) ->

        exec = (stm) ->
            try
                console.log stm
                execSync stm   # FIXME usar versao async
            catch e
                console.log "#{chalk.red('Oops!')} exited with error: \n\n#{e}"
                reject()

        if fn?
            r = fn context
            if Array.isArray r
                for l in r
                    if typeof l is 'function'
                        exec l2 for l2 in r2 if Array.isArray (r2 = l())
                    else
                        exec l
        resolve()

### load a yomano-package
tries to load from global and then from home location
###
loadPack = ->
    try
        pack           = require(context.pack_file)(chalk, fs, path)
        context.source = path.join path.dirname(require.resolve context.pack_file), 'source'
    catch e
        console.log e if context._verbose

    if not context.source? and config.get 'home'
        try
            local          = path.join config.get('home'), context.pack_file
            console.log local
            pack           = require(local)(chalk, fs, path)
            context.source = path.join path.dirname(require.resolve local), 'source'
        catch e
            console.log e if context._verbose

    unless context.source?
        console.log "#{chalk.red('\nOops!')} Can't find package #{chalk.yellow(context.pack_file)}"
        return Promise.reject()

    console.log "\nStarting: #{chalk.cyan pack.name}\n\n#{pack.description}\n"

    Promise.resolve()

### execute an inquirer
the default questions are merged with questions from the previous loaded pack
###
runQuestions = ->
    base_prompt = [
        name     : "name"
        message  : 'Application name'
        validate : (v) -> if /^[\w-]{1,}$/.test v then true else "Invalid or too short"
        default  : path.basename process.cwd()
    ,
        name    : 'dest'
        message : 'Destination'
        default : context.dest
        filter  : (v) ->
            path.resolve (
                v
                .replace /^(?:~|\$HOME)(\/|\\)/, (m, m1) -> process.env.HOME + m1
                .replace /^~(\w+)(\/|\\)/, (m, m1, m2) -> process.env.HOME + m2 + '..' + m2 + m1 + m2
            )
    ,
        name    : "owner"
        message : "Your name"
        default : config.get 'owner'
    ,
        name     : "email"
        message  : "Your email"
        validate : (v) -> if /^\w[\.\w]+@\w[\.\w]+\.\w{3,5}$/.test v then true else 'Not a valid email'
        default  : config.get 'email'
    ]

    inquirer.prompt base_prompt.concat pack.prompt || []

### check if target location is empty
if CLI option `force` is true the check is skiped
###
checkIfEmpty = ->
    new Promise (resolve, reject) ->
        if globby.sync(context.filters, {cwd:context.dest}).length and not context._force
            inquirer.prompt {
                name: 'q'
                type: 'confirm'
                message: 'Target folder already have files inside it. Continue?'
                default: no
            }
            .then (response) ->
                return resolve() if response.q
                return reject()
        else
            resolve()

### list all files matched by current glob filter
###
processGlob = ->
    globby context.filters, {cwd:context.source, mark:true, dot:true}

### execute the copy of every file matched by filter
some files previouly matched may still be skiped by internal filters
###
copyFiles = ->
    new Promise (resolve, reject) ->
        bar = new Progress 'copying [:bar] :percent',
            total: context.files.length
            width: 40
            callback: ->
                resolve()

        for file in context.files

            target = file

            install = yes
            final = no
            target = target.replace /// \( ([!+-]) ([a-z0-9]+) \) ///g, (m, m1, m2) ->
                if m1 == '!' and m2 == 'final'
                    final = yes
                    ''
                else if m2 of context
                    install = install && context[m2] if m1 == '+'
                    install = install && !context[m2] if m1 == '-'
                    ''
                else
                    m

            (bar.tick(); continue) unless install

            target = target.replace /\{(\w+)\}/g, (m, m1) -> context[m1] || m

            copyFile path.join(context.source, file), path.join(context.dest, target), context, final, -> bar.tick()

###
*
* Y O M A N O
*
###

config = new MyConfig()

processCli()

loadPack()
.then ->
    executeEvents pack.init, null
.then ->
    runQuestions()
.then (result) ->
    context = Object.assign {}, context, result
    if context._save
        config.set 'owner', result.owner
        config.set 'email', result.email
    checkIfEmpty()
.then ->
    console.log context if context._verbose
    executeEvents pack.after_prompt, context
.then ->
    processGlob()
.then (files) ->
    context.files = files
    console.log context
    executeEvents pack.before_copy, context
.then ->
    copyFiles()
.then ->
    executeEvents pack.after_copy, context
.then ->
    executeEvents pack.say_bye, context
.then ->
    console.log "\n\n#{chalk.green 'Success!'} -- #{chalk.grey context.name + ' is ready'}\n\n"
    process.exit 0
.catch (err) ->
    console.log chalk.red('Oops! ') + err
    process.exit 1
