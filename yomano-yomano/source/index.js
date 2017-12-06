module.exports = function(chalk, fs, path, gulp){
    return {
        name: "<%= name %>",
        description: "<%= name %> pack.\n"+chalk.gray("<%= description %>"),
        prompt: [
            {name:'test', type:'confirm', message:'Is a test?', default:false},
        ],
        init         : function(){},
        after_prompt : function(context){},
        before_copy  : function(context){},
        after_copy   : function(context){},
        say_bye      : function(context){},
        tasks: [
            {
                name: "task1",
                description: "task1 description",
                prompt: [
                    {name:'name', message:'Task name'},
                ],
                init         : function(){},
                after_prompt : function(context){},
                before_copy  : function(context){},
                after_copy   : function(context){},
                say_bye      : function(context){},
            }
        ],
    }
}
