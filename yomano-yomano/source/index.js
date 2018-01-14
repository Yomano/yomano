module.exports = function(chalk, fs, path, gulp){
    return {
        name: "<%= name %>",
        description: "<%= name %> pack.\n"+chalk.gray("<%= description %>"),
        prompt: [
            // {name:'example', type:'confirm', message:'Is it a example?', default:false},
%%% if(flat){
            {name:'doEdit', message:'Execute editor?', type:'confirm', default:true},
%%% }
        ],
%%% if(flat){
        init         : function(context){
            context.isFlat = true;
        },
%%% } else {
        init         : function(context){},
%%% }
        after_prompt : function(context){},
        before_copy  : function(context){},
        after_copy   : function(context){},
%%% if(flat){
        say_bye      : function(context){
            if(context.doEdit){
                return ['subl ' + context.realFiles[0]]
            }
        },
%%% } else {
        say_bye      : function(context){},
%%% }

%%% if(!flat){
        tasks: [
            // {
            //     name: "task1",
            //     description: "task1 description",
            //     prompt: [
            //         {name:'name', message:'Task name'},
            //     ],
            //     init         : function(){},
            //     after_prompt : function(context){},
            //     before_copy  : function(context){},
            //     after_copy   : function(context){},
            //     say_bye      : function(context){},
            // },
        ],
%%% }
    }
}
