module.exports = function(chalk){
	return {
		name: 'Yomano!',
		description: 'Yomano pack starter.',
        after_prompt : function(context){
            if(context.name.substring(0, 7) != 'yomano-'){
                console.log(chalk.red('\nOops!')+' A valid pack shoud be named as "'+chalk.yellow('yomano-')+'something"');
                process.exit(1);
            }
        },
	}
}
