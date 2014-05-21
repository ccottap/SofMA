function get_pool_roulette_wheel (population, need ) {
    var total_fitness = 0;
    for ( var i in population ) {
	total_fitness += population[i].value.fitness;
    }
    var wheel = new Array;
    for ( var i in population ) {
	wheel[i]  = population[i].value.fitness/total_fitness;
    }
    var slots = spin( wheel, population.length );
    var pool = new Array;
    var index = 0;
    do {
	var p = index++ % slots.length;
	var copies = slots[p];
	if ( ! copies ) 
	    continue; 
	for (var i = 1; i < copies; i++) {
	    pool.push( population[p] );
	}
    } while ( pool.length < need );
  
    return pool;
}

function spin( wheel, number_of_slots ) {
    var slots = new Array;
    for (var i in wheel ) {
	slots[i] = wheel[i]*number_of_slots;
    }
   return slots;
}

function produce_offspring( pool, offspring_size) {
    var crossed_strings = new Array;
    pool.shuffle;
    for ( var i = 0; i < offspring_size/2; i++ )  {
	var first = pool.pop();
	var second = pool.pop();
	crossed_strings.push( crossover( first, second ) );
    }
    var population = new Array;
    for ( i in crossed_strings ) {
	population.push( mutate(crossed_strings[i]) );
    }
    return population;
}


// applied over the first chromosome
function crossover( guy_1, guy_2 ) {
    var first_chromosome = guy_1.value._id;
    var second_chromosome = guy_2.value._id;
    var this_len = first_chromosome.length;
    var point_1 = Math.floor( Math.random()* this_len);
    var len = 1+Math.floor( Math.random()*(this_len - point_1 - 1));
     var resulting_chromosome= first_chromosome.substr(0,point_1) +
    second_chromosome.substr(point_1, len) +
	first_chromosome.substr(point_1+len, this_len - (point_1 + len ));
    return resulting_chromosome;
}

function mutate( guy ) {
    var mutation_point= Math.random(guy.length);
    var to_mutate =  guy.substr(0,mutation_point-1);
    to_mutate +=  (guy.charAt(mutation_point)  == "1")?"0":"1";
    to_mutate +=  guy.substr(mutation_point+1,guy.length);
    var other_guy = { _id : to_mutate,
		      str: to_mutate,
		      rnd: Math.random() };
    return other_guy;
}