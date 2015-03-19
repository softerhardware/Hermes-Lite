// main board size
L = 50;
W = 180;
T = 2;

// waveshare size, offset
Lw = 60;
Ww = 28;
Xw = 97.5;
ww = 21;
yw = 50.5;

B = 8;

// spacer heights
S1 = 6;
S2 = 11;
S3 = 20;
Ph = 2;

// spacer radii
Sr = 3;
Pr = 1.0;
Hr = 0.8;
$fn = 30;


module s1()
{
   cylinder(S1, r1=Sr, r2=Sr);
   translate([0,0,S1]) cylinder(Ph, r1=Pr, r2=Pr);
}

module s2()
{
   cylinder(S2, r1=Sr, r2=Sr);
}

module s3()
{
   difference() {
     cylinder(S3, r1=Sr, r2=Sr);
     translate ([0,0,3*S3/4]) cylinder(S3, r1=Hr, r2=Hr);
  }
}

module hermes_lite()

{

 difference() {
     cube([W,L,T]);
     translate ([B,B,0]) cube([W-2*B,L-2*B,T]);
 }
 difference() {
     translate ([Xw-Ww/2,-Lw,0]) cube([Ww,Lw,T]);
     translate ([Xw-Ww/2+B,-Lw+B,0]) cube([Ww-2*B,Lw-B,T]);
 }
 translate ([4,5.25,T] ) s1();
 translate ([4,47,T] ) s1();
 translate ([50.56,5.25,T] ) s1();
 translate ([50.56,47,T] ) s1();
 translate ([88,5.25,T] ) s1();
 translate ([88,47,T] ) s1();
 translate ([160,5.25,T]) s2();
 translate ([171,45,T]) s2();
 translate ([Xw-ww/2,-yw,T]) s3();
 translate ([Xw+ww/2,-yw,T]) s3();
}

hermes_lite();