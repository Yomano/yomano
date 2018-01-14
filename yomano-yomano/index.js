module.exports = function(chalk, fs, path, gulp){
    return {
        name: 'Yomano!',
        description: 'Yomano pack starter.',
        prompt: [
            {name:'description', message:'Description'},
            {name:'private', message:'Is a private pack?', type:'confirm', default:false},
            {name:'flat', message:'Is a flat file model?', type:'confirm', default:false},
        ],
        after_prompt : function(context){
            if(!context.name.startsWith('yomano-')){
                console.log(chalk.red('\nOops!')+' A valid pack shoud be named as "'+chalk.yellow('yomano-')+'something"');
                process.exit(1);
            }
        },
        tasks: [
            {
                name: 'task',
                description: 'Create a new Yomano task template',
                prompt: [
                    {name:'name', message:'Task´s name'},
                    {name:'description', message:'Description'},
                ],
                after_copy   : function(context){

                    // TODO editar o index.js to pacote yomano e inserir esse texto dentro da chave de tarefas!
                    "{"
                    "\n    name: "+context.name+","
                    "\n    description: "+context.description+","
                    "\n    prompt: ["
                    "\n        {name:'name', message:'Name'},"
                    "\n    ],"
                    "\n    init         : function(){},"
                    "\n    after_prompt : function(context){},"
                    "\n    before_copy  : function(context){},"
                    "\n    after_copy   : function(context){},"
                    "\n    say_bye      : function(context){},"
                    "\n},"
                },
            },
        ],
    }
}
