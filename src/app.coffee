chalk      = require 'chalk'
commander  = require 'commander'
execSync   = require('child_process').execSync
fs         = require 'fs'
globby     = require 'globby'
mkdirp     = require 'mkdirp'
path       = require 'path'
preprocess = require('preprocess').preprocessFile
Progress   = require 'progress'
prompt     = require 'prompt'
request    = require 'request'


commander
.version '0.0.1'
.option '-v, --verbose', 'Increase verbose mode'
.parse process.argv

commander.help() if commander.args.length isnt 1

pack_name = commander.args[0]

# TODO se nao existir tem que tentar baixar a pemba
#
pack = require("yomano-#{pack_name}")(chalk)

console.log "\nInstalling: #{chalk.cyan pack.name}\n\n#{pack.description}\n"

base_prompt = [
    name: "name"
    description: 'Application name'
    type: 'string'
    pattern: /^\w+$/
    message: 'Can\'t be empty'
    default: path.basename process.cwd()
    required: true
]

copyFile = (source, target, context, opt, cb) ->
    cbCalled = no

    done = (err) ->
        unless cbCalled
            cb? err
            cbCalled = yes

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


executeEvents pack.init

prompt.message = chalk.cyan pack_name
prompt.start()
prompt.get base_prompt.concat(pack.prompt), (err, result) ->
    context =
        platform: process.platform
        source: path.join path.dirname(require.resolve "yomano-#{pack_name}"), 'source'
        dest: process.cwd()
        name: result.name
        form: result
        filters: ['**/*', '**/.*']

    if pack.special?
        for s in pack.special
            for op in s[1].split ';'
                if op[..2] == 'if:'
                    context.filters.push "!#{s[0]}" unless context.form[op[3..]]

    executeEvents pack.after_prompt, context

    context.files = globby.sync context.filters, cwd:context.source, nodir:true

    # console.log context

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
            target = target.replace '{' + m[1] + '}', context.form[m[1]]

        copyFile path.join(context.source, file), path.join(context.dest, target), context, opt, -> bar.tick()
