module.exports = function(chalk, fs, path){
    return {
        name: 'yomano-test',
        description: 'yomano-test pack.\n'+chalk.gray('Yomano\'s features playground'),
        prompt: [
            {name:'test', type:'confirm', message:'Is a test?', default:false},
            {name:'a', type:'confirm', message:'Group A?', default:false},
            {name:'b', type:'confirm', message:'Group B?', default:false},
            {name:'c', type:'confirm', message:'Group C?', default:false},
            {name:'longText', type:'string', message:'Render Text', default:"Hi, I have quotes:\"'[] and tags: <b>bold</b>"},
        ],
        init: function() { return ['touch event-init', ] },
        after_prompt: function(context) { return ['touch event-after_prompt', 'touch boga'] },
        before_copy: function(context) { return ['touch event-before_copy', ] },
        after_copy: function(context) { return ['touch event-after_copy', ] },
        say_bye: function(context){
            // console.log('\n'+chalk.red('say_bye')+'\n');
            return [
                'touch event-say_bye',
            ]
        },
    }
}
