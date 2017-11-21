module.exports = function(chalk, fs, path){
    return {
        name: "<%= name %>",
        description: "<%= name %> pack.\n"+chalk.gray("<%= description %>"),
        prompt: [
            {name:'test', type:'confirm', message:'Is a test?', default:false},
        ],
        special: [
            ['test/*', 'if:test']
        ],
        init         : function(){},
        after_prompt : function(context){},
        before_copy  : function(context){},
        after_copy   : function(context){},
        say_bye      : function(context){},
    }
}
