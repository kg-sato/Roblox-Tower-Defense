import itertools, math
def lin(c): c/=255; return c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4
def unlin(c): c=max(0,min(1,c)); return 12.92*c if c<=0.0031308 else 1.055*c**(1/2.4)-0.055
M={'normal':[[1,0,0],[0,1,0],[0,0,1]],
'protan':[[0.152286,1.052583,-0.204868],[0.114503,0.786281,0.099216],[-0.003882,-0.048116,1.051998]],
'deutan':[[0.367322,0.860646,-0.227968],[0.280085,0.672501,0.047413],[-0.011820,0.042940,0.968881]],
'tritan':[[1.255528,-0.076749,-0.178779],[-0.078411,0.930809,0.147602],[0.004733,0.691367,0.303900]]}
def lab(rgb):
    r,g,b=[max(0,min(1,v)) for v in rgb]
    X=0.4124*r+0.3576*g+0.1805*b; Y=0.2126*r+0.7152*g+0.0722*b; Z=0.0193*r+0.1192*g+0.9505*b
    X/=0.95047; Z/=1.08883
    f=lambda t: t**(1/3) if t>0.008856 else 7.787*t+16/116
    fx,fy,fz=f(X),f(Y),f(Z)
    return (116*fy-16,500*(fx-fy),200*(fy-fz))
def sim(hexs,k):
    c=[lin(int(hexs[i:i+2],16)) for i in (1,3,5)]
    return [sum(M[k][r][j]*c[j] for j in range(3)) for r in range(3)]
def de(a,b): return math.dist(a,b)
sets={
'okabe7':{'orange':'#E69F00','skyblue':'#56B4E9','green':'#009E73','yellow':'#F0E442','blue':'#0072B2','vermilion':'#D55E00','purple':'#CC79A7'},
'ten':{'orange':'#E69F00','skyblue':'#56B4E9','green':'#009E73','yellow':'#F0E442','blue':'#0072B2','vermilion':'#D55E00','purple':'#CC79A7','white':'#F2F2F2','grey':'#7F7F7F','black':'#1A1A1A'}}
for name,s in sets.items():
    for k in M:
        labs={n:lab(sim(h,k)) for n,h in s.items()}
        worst=sorted((de(labs[a],labs[b]),a,b) for a,b in itertools.combinations(labs,2))[:3]
        print(name,k,[(round(d,1),a,b) for d,a,b in worst])
