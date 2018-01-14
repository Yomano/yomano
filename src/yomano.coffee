###!
--- yomano ---

Released under MIT license.

by Gustavo Vargas - @xgvargas - 2016

Original coffee code and issues at: https://github.com/Yomano/yomano
###

chalk      = require 'chalk'
ejs        = require 'ejs'
{execSync} = require 'child_process'
fs         = require 'fs'
globby     = require 'globby'
inquirer   = require 'inquirer'
jsesc      = require 'jsesc'
minimatch  = require 'minimatch'
mkdirp     = require 'mkdirp'
path       = require 'path'
ora        = require 'ora'
logSymbols = require 'log-symbols'
gulp       = require 'gulp'
commander  = new (require('commander').Command)('yomano')


rootPack = null
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
        .option '-f, --force', 'force instalation into non empty folder'
        .option '-v, --verbose', 'verbose mode'
        .action (packName, options) ->
            context._verbose  = options.verbose
            context._force    = options.force
            context.pack_name = packName
            context.pack_file = "yomano-#{packName}"

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
            console.log ''
            process.exit 0

    commander
        .command 'new'
        .description 'start a new pack for yomano'
        .option '-v, --verbose', 'verbose mode'
        .action (options) ->
            context._verbose  = options.verbose
            context.pack_name = 'new'
            context.pack_file = "../yomano-yomano"
            # context.dest = config.get('home') || context.dest

    commander
        .command 'task [task_name]'
        .description 'execute a task on a yomano project'
        .action (taskName, options) ->

            folders = context.dest.split /\/|\\/g
            loop
                context.dest = path.join '/', path.join.apply(null, folders)
                try
                    mark = fs.readFileSync path.join context.dest, '.yomano-root.json'
                break if mark
                folders.pop()
                unless folders.length
                    console.log "\n#{logSymbols.error} Could not found a yomano project in current tree\n"
                    process.exit 1

            console.log chalk.grey "\n#{logSymbols.info} Project root: #{context.dest}"
            process.chdir context.dest
            mark = JSON.parse mark.toString()

            context.pack_name = mark.name
            context.pack_file = "yomano-#{mark.name}"
            context.taskName = taskName
            loadPack()

            unless taskName
                tasks = Object.keys gulp.tasks
                tasks.push t.name for t in rootPack.tasks || []
                if tasks.length
                    console.log "#{logSymbols.info} Available tasks: #{tasks.sort().join(', ')}\n"
                else
                    console.log "#{logSymbols.error} No task are available for this project!\n"
                process.exit 0
            else
                if taskName of gulp.tasks
                    console.log "\n#{logSymbols.info} Running Gulp task `#{chalk.yellow(taskName)}`\n"
                    context.isGulp = true
                    gulp.start taskName, (err) ->
                        console.log "\n#{logSymbols.success} Done!\n"
                        process.exit 0

                else if (rootPack.tasks.find (t) -> t.name == taskName)
                    # console.log '\n'

                    # XXX nothing to do in here.... just let main code run....

                else
                    console.log "\nUnknown task `#{chalk.red(taskName)}` for project `#{chalk.cyan(context.pack_name)}`\n"
                    process.exit 1

            # process.exit 0

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

    options.escape ?= (input) -> jsesc input, {quotes:'double'}

    template = input.replace /^%%%\s*(.+)\s*$/gm, (m, m1) -> "<\%_ #{m1} -\%>"

    try
        ejs.render template, data, options
    catch e
        console.error e
        process.exit 1

### execute events
if event returns an array each string item will be executed in current shell. if item is
a function it will be executed and its output will be treated like the original one.
###
executeEvent = (evName, context) ->

    console.log "\n#{logSymbols.info} Executing event: #{chalk.yellow(evName)}" if context._verbose

    new Promise (resolve, reject) ->

        exec = (stm) ->
            try
                console.log "#{logSymbols.warning} Shell executing: #{chalk.red(stm)}" if context._verbose
                execSync stm   # FIXME usar versao async
            catch e
                console.log "#{chalk.red('Oops!')} exited with error: \n\n#{e}"
                reject()

        if pack[evName]?
            r = pack[evName] context
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
    return Promise.resolve() if context.taskName and rootPack
    try
        rootPack = require(context.pack_file)(chalk, fs, path, gulp)
        if context.taskName
            pack = (rootPack.tasks || []).find (t) -> t.name == context.taskName
            context.source = path.join path.dirname(require.resolve context.pack_file), 'tasks', context.taskName
        else
            pack = rootPack
            context.source = path.join path.dirname(require.resolve context.pack_file), 'source'
    catch e
        console.log '\n\n', e if e.code != 'MODULE_NOT_FOUND'

    if not context.source? and config.get 'home'
        try
            local = path.join config.get('home'), context.pack_file
            rootPack = require(local)(chalk, fs, path, gulp)
            if context.taskName
                pack = (rootPack.tasks || []).find (t) -> t.name == context.taskName
                context.source = path.join path.dirname(require.resolve local), 'tasks', context.taskName
            else
                pack = rootPack
                context.source = path.join path.dirname(require.resolve local), 'source'
        catch e
            console.log '\n\n', e if e.code != 'MODULE_NOT_FOUND'

    unless context.source?
        console.log "#{chalk.red('\nOops!')} Can't find package #{chalk.yellow(context.pack_file)}"
        return Promise.reject()

    # XXX pack will be undefined when runnning a gulp task
    if pack
        console.log "\nStarting: #{chalk.cyan pack.name}\n\n#{pack.description}\n"

    Promise.resolve()

### execute an inquirer
the default questions are merged with questions from the previous loaded pack
###
runQuestions = ->
    base_prompt = [
        name     : "name"
        message  : if context.isFlat then 'File name' else 'Application name'
        validate : (v) -> if /^[\w-]{1,}$/.test v then true else "Invalid or too short"
        # default  : if context.isFlat then '' else path.basename process.cwd()
    ,
        name    : 'dest'
        message : 'Destination'
        default : (r) ->
            if context.pack_name == 'new'
                path.join (config.get('home') || context.dest), r.name
            else
                context.dest
        filter  : (v) ->
            path.resolve (
                v
                .replace /^(?:~|\$HOME)(\/|\\{1,2})/, (m, m1) -> process.env.HOME + m1
                .replace /^~(\w+)(\/|\\{1,2})/, (m, m1, m2) -> process.env.HOME + m2 + '..' + m2 + m1 + m2
            )
    ]

    unless context.isFlat

        base_prompt[0].default = path.basename process.cwd()

        base_prompt = base_prompt.concat [
            name    : "owner"
            message : "Your name"
            default : config.get 'owner'
        ,
            name     : "email"
            message  : "Your email"
            validate : (v) -> if /^\w[\.\w]+@\w[\.\w]+\.\w{3,5}$/.test v then true else 'Not a valid email'
            default  : config.get 'email'
        ]

    if context.taskName
        if pack.prompt
            inquirer.prompt pack.prompt
        else
            return Promise.resolve {}
    else
        inquirer.prompt base_prompt.concat pack.prompt || []

### check if target location is empty
if CLI option `force` is true the check is skiped
###
checkIfEmpty = ->
    return Promise.resolve() if context.taskName or context.isFlat

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

        console.log '\nProcessing files...'
        spinner = ora().start 'Preparing to copy files...'

        nfiles = 0

        context.realFiles = []

        for file in context.files

            continue if minimatch file, '.yomanoignore', {matchBase:true, dot:true}

            target = file

            install = yes
            final = no
            target = target.replace /// \( ([!+-]) ([a-z0-9]+) \) ///gi, (m, m1, m2) ->
                if m1 == '!' and m2 == 'final'
                    final = yes
                    ''
                else if m2 of context
                    install = install && context[m2] if m1 == '+'
                    install = install && !context[m2] if m1 == '-'
                    ''
                else
                    m

            continue unless install

            target = path.join context.dest, target.replace /\{(\w+)\}/g, (m, m1) -> context[m1] || m

            context.realFiles.push target

            nfiles++
            if context._verbose
                spinner.info path.join(context.source, file) + ' --> ' + target
            else
                spinner.text = target

            # TODO quando estiver em modo flat deve verificar se o arquivo destino já existe e perguntar!!!

            if target[-1..] in '/\\'
                mkdirp.sync target
            else
                mkdirp.sync path.dirname(target)

                try
                    data = fs.readFileSync path.join(context.source, file)
                    data = render data.toString(), context unless final
                    fs.writeFileSync target, data
                catch e
                    spinner.fail 'Oops! Something went wrong...\n'
                    spinner.stop()
                    reject e

        spinner.succeed "Done! Copied #{nfiles} files.\n"
        spinner.stop()
        resolve()

###
*
* Y O M A N O
*
###

config = new MyConfig()

processCli()

unless context.isGulp
    loadPack()
    .then ->
        executeEvent 'init', context
    .then ->
        runQuestions()
    .then (result) ->
        context = Object.assign {}, context, result
        unless context.taskName or context.isFlat
            config.set 'owner', result.owner
            config.set 'email', result.email
        new Promise (resolve, reject) ->
            mkdirp context.dest, (err) ->
                return reject err if err
                resolve()
    .then ->
        process.chdir context.dest
        # unless context.pack_name == 'new' and not context.single
        unless context.isFlat
            root =
                name: context.pack_name
                path: context.source
                context: context
            fs.writeFileSync path.join(context.dest, '.yomano-root.json'), JSON.stringify root
        checkIfEmpty()
    .then ->
        executeEvent 'after_prompt', context
    .then ->
        processGlob()
    .then (files) ->
        context.files = files
        if context._verbose
            console.log "\n#{logSymbols.info} #{chalk.yellow('Complete context')}"
            console.dir context
        executeEvent 'before_copy', context
    .then ->
        copyFiles()
    .then ->
        executeEvent 'after_copy', context
    .then ->
        executeEvent 'say_bye', context
    .then ->
        if context.isFlat
            console.log "\n#{chalk.green 'Success!'} -- #{chalk.grey 'Flat Model `' + context.name + '` created!'}\n"
        else if context.taskName
            console.log "\n#{chalk.green 'Success!'} -- #{chalk.grey 'Task `' + context.taskName + '` applied!'}\n"
        else
            console.log "\n#{chalk.green 'Success!'} -- #{chalk.grey 'Project `' + context.name + '` is ready for you!'}\n"
            tasks = Object.keys gulp.tasks
            tasks.push t.name for t in pack.tasks || []
            console.log "Available tasks: #{tasks.sort().join(', ')}\n" if Object.keys(gulp.tasks).length
        process.exit 0
    .catch (err) ->
        console.log '\n'
        console.log chalk.red('Oops! ') + err if err
        process.exit 1
