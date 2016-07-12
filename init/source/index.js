module.exports = function(chalk){
	return {
		name: '<%= name %>',
		description: '<%= name %> pack.\n'+chalk.gray('<%= description %>'),
		prompt: [
			{name:'test', type:'boolean'},
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
