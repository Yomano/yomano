chalk      = require 'chalk'
commander  = require 'commander'
execSync   = require('child_process').execSync
fs         = require 'fs'
globby     = require 'globby'
mkdirp     = require 'mkdirp'
path       = require 'path'
positive   = require 'positive'
preprocess = require('preprocess').preprocessFile
Progress   = require 'progress'
prompt     = require 'prompt'

# FIXME precisa escapar as strings

class MyConfig
    constructor: ->
        @configFile = path.join (process.env.HOME || process.env.USERPROFILE), '.yomano.json'
        try
            @data = require @configFile
        catch e
            @data = {}

    get: (id) -> @data[id]
    set: (id, val) ->
        @data[id] = val
        fs.writeFileSync @configFile, JSON.stringify @data, null, 4


copyFile = (source, target, context, opt, cb) ->
    cbCalled = no

    done = (err) ->
        unless cbCalled
            cb? err
            cbCalled = yes

    return done() if source[-13..] == '.yomanoignore'

    console.log target if commander.verbose

    if target[-1..-1] in '/\\'
        mkdirp target, (err) -> done err
    else
        mkdirp path.dirname(target), (err) ->
            return done err if err
            if 'final' in opt
                rd = fs.createReadStream source
                rd.on "error", (err) -> done err
                wr = fs.createWriteStream target
                wr.on "error", (err) -> done err
                wr.on "close", (ex) -> done()
                rd.pipe wr
            else
                preprocess source, target, context, done, type: 'js'


executeEvents = (ev, context) ->
    if ev?
        r = ev context
        if Array.isArray r
            for l in r
                if typeof l is 'function'
                    l()
                else
                    console.log l
                    code = execSync l
                    process.exit code if code
    return


config = new MyConfig()

context =
    platform: process.platform
    dest: process.cwd()
    date:
        year: new Date().getFullYear()
    filters: ['**/*', '**/.*']

if globby.sync(context.filters, cwd:context.dest).length
    process.exit 1 unless positive "#{chalk.red('Oops!')} Target folder already have files inside. Continue? [No]: ", no

commander
    .version require('../package.json').version

commander
    .command 'setup <pack_name>'
    .description 'setup a new environment'
    .option '-s, --save', 'save personal information'
    .option '-v, --verbose', 'verbose mode'
    .action (pack) ->
        context.pack_name = pack
        context.pack_file = "yomano-#{pack}"
    # .on '--help', -> console.log """"""

commander
    .command 'new'
    .description 'start a new pack for yomano'
    .action ->
        context.pack_name = 'new'
        context.pack_file = "../init"

commander
    .command 'home [path]'
    .description 'get/set personal home folder'
    .action (path) ->
        config.set 'home', path if path?
        console.log "\nYour current home folder: #{chalk.yellow config.get 'home'}"
        process.exit 0

commander.parse process.argv

commander.help() unless context.pack_name?

try
    pack = require(context.pack_file)(chalk)
    context.source = path.join path.dirname(require.resolve context.pack_file), 'source'

if not context.source? and config.get 'home'
    try
        local = path.join config.get('home'), context.pack_file
        pack = require(local)(chalk)
        context.source = path.join path.dirname(require.resolve local), 'source'

unless context.source?
    console.log "#{chalk.red('\nOops!')} Can't find package #{chalk.yellow(context.pack_file)}"
    process.exit 1

console.log "\nInstalling: #{chalk.cyan pack.name}\n\n#{pack.description}\n"
executeEvents pack.init

base_prompt = [
    name: "name"
    description: 'Application name'
    type: 'string'
    pattern: /^[\w-]+$/
    message: 'Can\'t be empty'
    default: path.basename process.cwd()
    required: true
,
    name: "owner"
    default: config.get 'owner'
    required: true
,
    name: "email"
    default: config.get 'email'
    required: true
]
schema = if pack.prompt? then base_prompt.concat(pack.prompt) else base_prompt

prompt.message = chalk.cyan context.pack_name
prompt.start()
prompt.get schema, (err, result) ->

    if commander.save
        config.set 'owner', result.owner
        config.set 'email', result.email

    context[r] = result[r] for r of result

    if pack.special?
        for s in pack.special
            for op in s[1].split ';'
                if op[..2] == 'if:'
                    context.filters.push "!#{s[0]}" unless context[op[3..]]
                if op[..3] == 'if:!'
                    context.filters.push "!#{s[0]}" if context[op[4..]]

    executeEvents pack.after_prompt, context

    context.files = globby.sync context.filters, cwd:context.source, mark:true

    executeEvents pack.before_copy, context

    bar = new Progress 'copying [:bar] :percent',
        total: context.files.length
        width: 40
        callback: ->
            executeEvents pack.after_copy, context
            executeEvents pack.say_bye, context
            process.exit 0

    for file in context.files
        opt = []
        target = file
        if pack.special?
            for s in pack.special
                if s[0] == file
                    opt = s[1].split ';'

        mark = /// \{ (\w+) \} ///g
        while (m = mark.exec file)?
            target = target.replace '{' + m[1] + '}', context[m[1]]

        for o in opt
            if o[..6] == 'rename:'
                val = o[7..].split ':'
                target.replace val[0], val[1]

        copyFile path.join(context.source, file), path.join(context.dest, target), context, opt, -> bar.tick()

    return
