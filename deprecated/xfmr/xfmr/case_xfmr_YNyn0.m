% Case to test space based matlab matrix
% And other hard to parse cases
% also test data without a generator cost model

function mpc = case_xfmr_Yy0
mpc.version = '2';
mpc.baseMVA =  100.00;

%% bus data
%	bus_id	type    Pd      Qd	    Gs	    Bs	    area	Vm	    Va	    baseKV  zone	Vmax	Vmin
mpc.bus = [
    1       3       0.000   0.000   0.00    0.00    1       1.00    0.00    12.47   1       1.10    0.90;
    2       1       6.000   0.000   0.00    0.00    1       1.00	0.00    4.16    1       1.10    0.90;
];

%% bus harmonic data 
%column_names%  nh_1    nh_5    nh_7    nh_13   nh_15   nh_19   thdmax  
mpc.bus_harmonics = [
                1.000   0.0000  0.0000  0.0000  0.0000  0.0000  8.0
                1.000   0.4500  0.2500  0.0800  0.0600  0.0400  8.0
]

%% generator data
%   bus     Pg      Qg      Qmax    Qmin    Vg      mBase   status  Pmax    Pmin
mpc.gen = [
    1       0.0     0.0     200.00  -200.00 1.05    100.0   1       400.00  0.0;
];

%% generator cost data
% 	2   up      down	n       c2      c1      c0
mpc.gencost = [
	2   0.0	    0.0	    3	    0.1100	5.0000  0.0000;
];

%% branch data
%   f_bus	t_bus	r	    x	    b	    rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [ 
];

%% transformer data
%column_names%  f_bus   t_bus   xsc     r1      r2      vg      gnd1    gnd2    re1     xe1     re2     xe2   
mpc.xfmr = [
                1       2       0.0229  0.0003  0.0003  'Yy0'   1       1       0.0     0.0     0.0     0.0
];
