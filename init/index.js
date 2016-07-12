module.exports = function(chalk, fs, path){
	return {
		name: 'Yomano!',
		description: 'Yomano pack starter.',
        prompt: [
            {name:'description', message:'description'},
            {name:'private', message:'Is a private pack?', type:'confirm', default:false},
        ],
        after_prompt : function(context){
            if(context.name.substring(0, 7) != 'yomano-'){
                console.log(chalk.red('\nOops!')+' A valid pack shoud be named as "'+chalk.yellow('yomano-')+'something"');
                process.exit(1);
            }
        },
	}
}
