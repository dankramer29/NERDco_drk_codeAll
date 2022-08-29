% Word lists Marc emailed me.
clear
X{1} = 'pat 	lawn 	cot 	mouse	teak 	dine	bed 	pine	dog 	sum 	seep 	not 	pig 	back 	pig 	pool	cane 	coil 	turn	foot	same 	pearl 	cop 	pawn 	puff 	boon 	hoot 	dupe 	cool	took 	mice	rye	full 	soul	bell	peace 	burn	sag	fawn	sewn	cold 	pad 	loon	bite	boss	team 	doll 	led 	soon 	sun 	seen 	tight	terse	pull	may 	big 	pace 	case	mop 	oil 	fob	name 	reel 	dark 	cut 	law 	puck 	neat 	soup	coin	cook 	same 	coil 	sick 	gale 	sick 	bus 	sat 	sun	bent 	toll	pan 	loan	fit 	goat	teal 	dim 	fed 	town	duck 	got 	rest 	pin 	bad 	boy	dig 	cow	cop 	soil 	tap 	game 	feel 	mark 	cud 	raw 	moon 	pub 	beat 	feat 	kit 	look 	map 	rate 	sale 	will 	sip 	sale 	kick 	peak 	bout 	sass 	bun     den     fold    lake ';
X{2} = 'rust 	dig 	red 	fern	dud	sup 	seek 	pot 	best 	pip 	bass 	pay 	wig 	pane 	cake 	top 	toil 	tack 	fall	tame 	now	bar	cuff 	paw 	pus 	beak 	seat 	type	kick 	moat 	sane 	hill 	tale 	lick 	bug 	sack 	gun	ten	sold 	pack 	lace 	white	dust 	tear 	dip 	wed 	din 	dub 	sub 	seem 	pit 	bat 	down	rig 	pay 	comb	boil 	tam 	fig 	came 	keel 	park 	cuss 	den 	pup 	bead 	meat 	lip 	man 	rake 	sake 	tool	sit 	pale 	pock 	peat 	buck 	sad 	run	rent 	god	pass 	lame 	sit 	dude	wool	dawn 	sud 	sued 	loot 	nest 	pick 	ban 	gay 	fig 	pipe 	foil 	tab 	fine	foam	like	cud 	saw 	ten 	pun 	beam 	boat	rip 	kid 	book 	mad 	rice	safe 	bull	sin 	mile	tick 	poll	buff 	sap 	noon	heel 	heap 	hot ';
X{3} = 'hook 	hit 	hoop	heal 	heat 	hun 	hear 	hark 	hole	hop 	heath 	hone	hood	bang 	gang 	king 	fang 	rang 	sing 	sung 	sang 	long	dung 	hang 	rung	wrong	wing	rush	mush	gosh	sham	shone	shook 	shed 	ship	fish	cash	sheep 	shop 	shows	thaw 	thin	thank	thing	thong	path 	math 	bath 	goth	teeth	tooth	faith	both	zip	zap	raze 	fizz 	peas 	tease 	pays	lies	zag	wise	was	way 	west 	went 	wife	word	worse	wick 	wine	wane	wash	yen	yes	yep	yawn	yam	yikes	yell	you	yon	yoke	youth	yule	young	yuck	asia	garage	massage	genre	seizure	beige	persian	usual	measure	version	vision	vest 	heave 	save 	rave 	turf	pave 	cave 	vet	shove	vote	shave	vice	vore	vows	van	vile	love	live	leave	vine	move	wave 	veil	voice	give';
X{4} = 'seethe 	than	thee	they	them	those	though	there	then	this	bathe	loathe	teethe	that	tithe	page 	jaw 	just 	thatch	reach	chose	choose	chat	chin	match	watch	beach 	peach 	chip	pitch	chow	much	hitch	dutch	teach 	choice	ride	might	fight	light	page	sage	luge	josh	jam	gel	jab	job	gem	jive	joke	jazz	rage	gage	gouge	huge	cage	change	blue	true	fool	flew	roof	hurl	bird';

wordsAll = {};
for iSet = 1 : numel( X )
    words{iSet} = strsplit( X{iSet});
    words{iSet} = strtrim( words{iSet} );
    
    deleteInds = [];
    for i = 1 : numel( words{iSet} )
        if isempty( words{iSet}{i} ) 
            deleteInds(end+1) = i;
        else
            if ismember( words{iSet}{i}, wordsAll )
                fprintf('  removing %s for being redundant with previous sets\n', ...
                    words{iSet}{i} );
                deleteInds(end+1) = i;
            end
        end        
    end
    words{iSet}(deleteInds) = [];
    rawWords = words{iSet};
    words{iSet} = unique( words{iSet} );
    fprintf('Set %i: %i words (unique of original %i in provided list)\n', iSet, numel( words{iSet} ), ...
        numel( rawWords ))
    wordsAll = [wordsAll, words{iSet}];
    
end
fprintf('TOTAL: %i words\n',  sum( cellfun(@numel, words ) ) )

wordsAll = [words{1}, words{2}, words{3}, words{4}];
uniqueWordsAll = unique( wordsAll );
fprintf('Overall %i unique words (%i in list)\n', numel( uniqueWordsAll ), numel( wordsAll ) );


%% Print out the code I need
iList = 1;
startNumberAt = 1001;

iList = 2;
startNumberAt = 1119;

iList = 3;
startNumberAt = 1235;

iList = 4;
startNumberAt = 1359;

%% Code for movementTypes.m
for i = 1 : numel( words{iList} )
    myWord = words{iList}{i};
    fprintf('WORDS_%s(%i)\n', upper( myWord ), startNumberAt + i - 1 )
end


%% Code for getMovementText.m
for i = 1 : numel( words{iList} )
    myWord = words{iList}{i};
    fprintf('case uint16(movementTypes.WORDS_%s)\n', upper( myWord ) )
    fprintf(' retVal = ''Prepare: "%s%s"'';\n', upper( myWord(1) ), lower(myWord(2:end ) ) )
end

%% Code for the param script
for i = 1 : numel( words{iList} )
    myWord = words{iList}{i};
    fprintf('movementTypes.WORDS_%s, ...\n', upper( myWord ) )
end