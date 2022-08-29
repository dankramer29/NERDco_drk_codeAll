function [electrode, xpos, ypos] = CerebusToCurly(X)
%% takes in cerebus channel numbers
%% spits out relevant parameters on Curly 
%%  electrode numbers, xposition and yposition on physical array


whichBank = floor((X-1)/32)+1;
whichNum = mod(X-1,32)+1;

banks{1} = [78 88 68 58 56 48 57 38 47 28 37 27 36 18 45 17 ...
    46  8 35 16 24  7 26  6 25  5 15  4 14  3 13  2];
banks{2} = [77 67 76 66 75 65 74 64 73 54 63 53 72 43 62 55 ...
    61 44 52 33 51 34 41 42 31 32 21 22 11 23 10 12];
banks{3} = [96 87 95 86 94 85 93 84 92 83 91 82 90 81 89 80 ...
    79 71 69 70 59 60 50 49 40 39 30 29 19 20  1  9];

xys = [
9	1
9	2
9	3
9	4
9	5
9	6
9	7
9	8
8	0
8	1
8	2
8	3
8	4
8	5
8	6
8	7
8	8
8	9
7	0
7	1
7	2
7	3
7	4
7	5
7	6
7	7
7	8
7	9
6	0
6	1
6	2
6	3
6	4
6	5
6	6
6	7
6	8
6	9
5	0
5	1
5	2
5	3
5	4
5	5
5	6
5	7
5	8
5	9
4	0
4	1
4	2
4	3
4	4
4	5
4	6
4	7
4	8
4	9
3	0
3	1
3	2
3	3
3	4
3	5
3	6
3	7
3	8
3	9
2	0
2	1
2	2
2	3
2	4
2	5
2	6
2	7
2	8
2	9
1	0
1	1
1	2
1	3
1	4
1	5
1	6
1	7
1	8
1	9
0	1
0	2
0	3
0	4
0	5
0	6
0	7
0	8
];

for nn = 1:3
    inds = find(whichBank==nn);
    electrode(inds) = banks{nn}(whichNum(inds));
end

xpos = xys(electrode,1);
ypos = xys(electrode,2);
