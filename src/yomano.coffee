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


###
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

###
###
render = (input, data = {}, options = {}) ->

    options.escape = (input) -> jsesc input, quotes:'double'

    template = input.replace /^%%%\s*(.+)\s*$/gm, (m, m1) -> "<\%_ #{m1} -\%>"

    try
        ejs.render template, data, options
    catch e
        console.error e
        process.exit 1

###
###
copyFile = (source, target, context, opt, cb) ->
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
                data = render data.toString(), context unless 'final' in opt
                fs.writeFile target, data, (err) -> done err

###
###
executeEvents = (ev, context) ->
    exec = (stm) ->
        try
            console.log stm
            execSync stm
        catch e
            console.log "#{chalk.red('Oops!')} exited with error: \n\n#{e}"
            process.exit 1

    if ev?
        r = ev context
        if Array.isArray r
            for l in r
                if typeof l is 'function'
                    exec l2 for l2 in r2 if Array.isArray (r2 = l())
                else
                    exec l
    return

###
###
loadPack = (context) ->
    try
        pack           = require(context.pack_file)(chalk, fs, path)
        context.source = path.join path.dirname(require.resolve context.pack_file), 'source'

    if not context.source? and config.get 'home'
        try
            local          = path.join config.get('home'), context.pack_file
            pack           = require(local)(chalk, fs, path)
            context.source = path.join path.dirname(require.resolve local), 'source'

    unless context.source?
        console.log "#{chalk.red('\nOops!')} Can't find package #{chalk.yellow(context.pack_file)}"
        process.exit 1

    console.log "\nStarting: #{chalk.cyan pack.name}\n\n#{pack.description}\n"
    executeEvents pack.init

    pack

# ---------------------------------------

config = new MyConfig()

context =
    platform : process.platform
    dest     : process.cwd()
    filters  : ['**/*']
    date:
        year: new Date().getFullYear()

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
    .action ->
        context.pack_name = 'new'
        context.pack_file = "../init"

commander
    .command 'task <task_name>'
    .description 'execute a task on a yomano project'
    .action (task, options) ->
        console.log '\n\nto be implemented\n'
        process.exit 1

commander
    .command 'home [path]'
    .description 'get/set personal home folder'
    .action (path) ->
        config.set 'home', path if path?
        console.log "\nYour current home folder: #{chalk.yellow config.get 'home'}"
        process.exit 0

commander.parse process.argv

commander.help() unless context.pack_name?

# if globby.sync(context.filters, cwd:context.dest).length and not context._force
#     process.exit 1 unless positive "#{chalk.red('Oops!')} Target folder already have files inside. Continue? [No]: ", no

pack = loadPack context

base_prompt = [
    name     : "name"
    message  : 'Application name'
    validate : (v) -> if /^[\w-]{1,}$/.test v then true else "Invalid or too short"
    default  : path.basename process.cwd()
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

inquirer.prompt if pack.prompt? then base_prompt.concat(pack.prompt) else base_prompt
.then (result) ->
    if context._save
        config.set 'owner', result.owner
        config.set 'email', result.email

    context = Object.assign {}, context, result

    console.log context if context._verbose

    # process.exit 1

    for s in pack.special || []
        for op in s[1].split ';'
            if op[..2] == 'if:' and op[3] != '!'
                context.filters.push "!#{s[0]}" unless context[op[3..]]
            if op[..3] == 'if:!'
                context.filters.push "!#{s[0]}" if context[op[4..]]

    executeEvents pack.after_prompt, context

    context.files = globby.sync context.filters, {cwd:context.source, mark:true, dot:true}

    executeEvents pack.before_copy, context

    bar = new Progress 'copying [:bar] :percent',
        total: context.files.length
        width: 40
        callback: ->
            executeEvents pack.after_copy, context
            executeEvents pack.say_bye, context
            process.exit 0

    for file in context.files

        target = file

        test    = /// \( ([+-])? ([a-z0-9]+) \) ///g
        install = yes
        while (m = test.exec file)?
            if m[2] of context
                install = install && context[m[2]] if m[1] == '+' || not m[1]?
                install = install && !context[m[2]] if m[1] == '-'
                target  = target.replace m[0], ''

        (bar.tick(); continue) unless install

        opt = []
        for s in pack.special || []
            if minimatch target, s[0], {dot:true, nocase:true}
                opt = s[1].split ';'

        mark = /// \{ (\w+) \} ///g
        while (m = mark.exec file)?
            target = target.replace '{' + m[1] + '}', context[m[1]] if m[1] of context

        for o in opt
            if o[..6] == 'rename:'
                val    = o[7..].split ':'
                target = target.replace val[0], val[1]

        copyFile path.join(context.source, file), path.join(context.dest, target), context, opt, -> bar.tick()

.catch (err) -> console.log err
