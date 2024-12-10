
for i=1:1:90
    idex = find(zAngle==i-1);
    average(i,1) = sum(path(idex).*detWeight(idex))./sum(detWeight(idex));
end

plot(1:90,average,'.')