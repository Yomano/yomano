commander  = require 'commander'
chalk      = require 'chalk'
prompt     = require 'prompt'
globby     = require 'globby'
path       = require 'path'
fs         = require 'fs'
Progress   = require 'progress'
mkdirp     = require 'mkdirp'
preprocess = require('preprocess').preprocessFile
execSync   = require('child_process').execSync

# commander
# .version '0.0.1'
# .option '-P, --pineapple', 'Add pineapple'
# .parse process.argv

pack_name = 'xhex'

# TODO se nao existir tem que tentar baixar a pemba
pack = require("aaa-#{pack_name}")(chalk)

console.log "\nInstalling: #{chalk.cyan pack.name}\n\n#{pack.description}\n\n"

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

prompt.start()
prompt.get base_prompt.concat(pack.prompt), (err, result) ->
    context =
        platform: process.platform
        source: path.join path.dirname(require.resolve "aaa-#{pack_name}"), 'source'
        dest: process.cwd()
        name: result.name
        form: result
        filters: ['**/*', '**/.*']

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

    for file in context.files
        opt = []
        target = file
        for s in pack.special
            if s[0] == file
                opt = s[1].split ';'

        mark = /// \{ (\w+) \} ///g
        while (m = mark.exec file)?
            target = target.replace '{' + m[1] + '}', context.form[m[1]]

        copyFile path.join(context.source, file), path.join(context.dest, target), context, opt, -> bar.tick()
