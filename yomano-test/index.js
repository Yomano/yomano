module.exports = function(chalk, fs, path, gulp){

    if(gulp) {
        gulp.task('task1', function(cb){
            console.log('executando tarefa 1');
            cb();
        });
        gulp.task('task2', ['task1'], function(cb){
            console.log('executando tarefa no. 2');
            setTimeout(function(){cb()}, 1000);
        });
    }

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
        after_prompt: function(context) { return ['touch event-after_prompt', ] },
        before_copy: function(context) { return ['touch event-before_copy', ] },
        after_copy: function(context) { return ['touch event-after_copy', ] },
        say_bye: function(context){
            // console.log('\n'+chalk.red('say_bye')+'\n');
            return [
                'touch event-say_bye',
            ]
        },
        tasks: [
            {
                name: 'boga1',
                description: 'sou a tarefa boga do pacote yomano-test',
                prompt: [
                    {name:'thing', type:'confirm', message:'Should I do that thing?', default:true},
                ],
                init: function() { return ['touch boga1-init', ] },
                after_prompt: function(context) { return ['touch boga1-after_prompt', ] },
                before_copy: function(context) { return ['touch boga1-before_copy', ] },
                after_copy: function(context) { return ['touch boga1-after_copy', ] },
                say_bye: function(context){ return ['touch boga1-say_bye', ] },
            },
        ]
    };
}
