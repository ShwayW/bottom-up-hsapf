function [str] = param2str(p)
% Written by Justin Stevens and Matt Gallivan

arguments 
    p (1,:) double
end 

% alg.string = 'if(G<j+k*H,a*H+b*G+c,if(G<l+m*H,d*H+e*G+f,g*H+h*G+i))';

%{
    p[0]  => a (alpha1)
    p[1]  => b (beta1)
    p[2]  => c (gamma1)
    p[3]  => d (alpha2)
    p[4]  => e (beta2)
    p[5]  => f (gamma2)
    p[6]  => g (alpha3)
    p[7]  => h (beta3)
    p[8]  => i (gamma3)
    p[9]  => j (psi1)
    p[10] => k (phi1)
    p[11] => l (psi2)
    p[12] => m (phi2)
    
    g-score => G
    h-score => H    
%}

if(~isnan(p(4)))
    % 13 parameter version 
    str = sprintf("if(G<%.2f+%.2f*H,%.2f*H+%.2f*G+%.2f,if(G<%.2f+%.2f*H,%.2f*H+%.2f*G+%.2f,%.2f*H+%.2f*G+%.2f))", ...
        p(10), p(11), p(1), p(2), p(3), p(12), p(13), p(4), p(5), p(6), p(7), p(8), p(9));
else
    % 3 parameter version 
    str = sprintf("%.2f*H+%.2f*G+%.2f", p(1), p(2), p(3)); 
end 

str = char(str); 

end