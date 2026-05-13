% ==========================================================================
% RDHABPCE.m
% Reversible Data Hiding with Automatic Brightness Preserving
% Contrast Enhancement
%
% Paper: Kim S., Lussi R., Qu X., Huang F., Kim H.J.
%        IEEE Transactions on Circuits and Systems for Video Technology,
%        Vol. 29, No. 8, pp. 2271-2284, August 2019.
%        DOI: 10.1109/TCSVT.2018.2869935
%
% Algorithm overview:
%   Two-sided histogram expansion with automatic brightness preservation.
%   At each round:
%     - Find two peak bins pL, pR from the histogram
%     - Compare current brightness B' to original B
%     - Choose expansion side (left or right) to minimise |B - B'|
%     - Shift outer pixels to create space; embed bit at peak pixel
%   Recovery: read pL/pR chain from header; reverse rounds.
%
% Run:  RDHABPCE     (full demo — 8 test images, 4 embedding capacities)
% ==========================================================================
function RDHABPCE()
    clc; close all;
    fprintf('=== RDHABPCE: Automatic Brightness Preserving CE ===\n');
    fprintf('    Kim et al., IEEE TCSVT 29(8), 2271-2284, 2019\n\n');

    imgs  = generate_test_images();
    names = {'Brain01','Brain02','chest','xray','Lena','Baboon','Peppers','Boat'};
    cap_vals = [5000 10000 20000 50000];

    % Experiment 1: PSNR vs capacity
    fprintf('\n--- Exp 1: PSNR (dB) ---\n');
    fprintf('%-10s', 'Image');
    for c = cap_vals, fprintf('%12d', c); end; fprintf('\n');
    fprintf('%s\n', repmat('-',1,58));
    for k = 1:numel(names)
        fprintf('%-10s', names{k});
        for cap = cap_vals
            rng(42); pay = randi([0 1],1,cap,'uint8');
            [I_emb,~] = rdhabpce_embed(imgs{k}, pay);
            fprintf('%12.2f', compute_psnr(imgs{k}, I_emb));
        end
        fprintf('\n');
    end

    % Experiment 2: Brightness preservation
    fprintf('\n--- Exp 2: Brightness difference |B - B_emb| ---\n');
    fprintf('%-10s', 'Image');
    for c = cap_vals, fprintf('%12d', c); end; fprintf('\n');
    fprintf('%s\n', repmat('-',1,58));
    for k = 1:numel(names)
        fprintf('%-10s', names{k});
        for cap = cap_vals
            rng(42); pay = randi([0 1],1,cap,'uint8');
            [I_emb,~] = rdhabpce_embed(imgs{k}, pay);
            dB = abs(mean(double(I_emb(:))) - mean(double(imgs{k}(:))));
            fprintf('%12.4f', dB);
        end
        fprintf('\n');
    end

    % Experiment 3: Reversibility
    fprintf('\n--- Exp 3: Reversibility (20000 bits) ---\n');
    for k = 1:numel(names)
        rng(42); pay = randi([0 1],1,20000,'uint8');
        [I_emb, meta] = rdhabpce_embed(imgs{k}, pay);
        [I_rec, D_ext] = rdhabpce_extract(I_emb, meta);
        ok   = isequal(imgs{k}, I_rec);
        n_ext = min(numel(D_ext), numel(pay));
        errs  = sum(D_ext(1:n_ext) ~= pay(1:n_ext));
        fprintf('  %-10s → Reversible: %s | Bit errors: %d\n', names{k}, string(ok), errs);
    end
    fprintf('\nDone.\n');
end

% ==========================================================================
%  ALGORITHM 1 — EMBEDDING
% ==========================================================================
function [I_emb, meta] = rdhabpce_embed(I, payload)
% Inputs:
%   I       – uint8 grayscale image
%   payload – binary uint8 row vector
% Outputs:
%   I_emb   – marked image
%   meta    – side information for extraction

    img    = double(I(:));
    N      = numel(img);
    B_orig = mean(img);

    pL_chain = [];  pR_chain = [];  d_chain = [];
    pay_ptr  = 1;   n_emb = 0;

    for round = 1:256
        counts = histcounts(img, 0:256);

        % ---- Find two highest bins pL < pR --------------------------------
        [sorted_c, sorted_i] = sort(counts,'descend');
        if sorted_c(2) == 0, break; end
        top2 = sort(sorted_i(1:2) - 1);
        pL   = top2(1);  pR = top2(2);
        if pR - pL < 2,  break; end     % no space between them

        % ---- Brightness direction: choose side that corrects drift --------
        B_curr = mean(img);
        % Right expansion: pixels > pR shift right → increases B
        % Left expansion:  pixels < pL shift left  → decreases B
        if B_curr > B_orig
            d = 0;   % left: reduces B back toward B_orig
        else
            d = 1;   % right: increases B back toward B_orig
        end

        pL_chain(end+1) = pL; %#ok<AGROW>
        pR_chain(end+1) = pR; %#ok<AGROW>
        d_chain(end+1)  = d;  %#ok<AGROW>

        if d == 1      % ---- RIGHT expansion: expand pR into pR+1 ----------
            % Shift pixels > pR right by 1
            img(img > pR) = img(img > pR) + 1;
            % Embed bits at pR pixels
            pR_idx = find(img == pR);
            for ii = 1:numel(pR_idx)
                if pay_ptr <= numel(payload)
                    img(pR_idx(ii)) = pR + payload(pay_ptr);
                    pay_ptr = pay_ptr + 1;
                    n_emb   = n_emb + 1;
                end
            end
        else           % ---- LEFT expansion: expand pL into pL-1 -----------
            % Shift pixels < pL left by 1
            img(img < pL) = img(img < pL) - 1;
            % Embed bits at pL pixels
            pL_idx = find(img == pL);
            for ii = 1:numel(pL_idx)
                if pay_ptr <= numel(payload)
                    img(pL_idx(ii)) = pL - payload(pay_ptr);
                    pay_ptr = pay_ptr + 1;
                    n_emb   = n_emb + 1;
                end
            end
        end

        if pay_ptr > numel(payload), break; end
    end

    % Store chain header in last 32 pixels' LSBs (pL_last 8b + pR_last 8b + n_rounds 8b + d_last 8b)
    n_rounds   = numel(pL_chain);
    header_val = [pL_chain(end), pR_chain(end), n_rounds, d_chain(end)];
    header_bits = [];
    for hv = header_val
        header_bits = [header_bits, uint8(dec2bin(hv,8)'-'0')]; %#ok<AGROW>
    end
    for bi = 1:32
        img(N-32+bi) = bitset(uint8(img(N-32+bi)), 1, header_bits(bi));
    end

    I_emb = uint8(reshape(img, size(I)));
    meta  = struct('pL_chain',pL_chain, 'pR_chain',pR_chain, ...
                   'd_chain',d_chain, 'n_rounds',n_rounds, 'n_emb',n_emb);
end

% ==========================================================================
%  ALGORITHM 2 — EXTRACTION AND RECOVERY
% ==========================================================================
function [I_rec, D_ext] = rdhabpce_extract(I_emb, meta)
    img      = double(I_emb(:));
    N        = numel(img);
    pL_chain = meta.pL_chain;
    pR_chain = meta.pR_chain;
    d_chain  = meta.d_chain;
    n_rounds = meta.n_rounds;

    D_ext = [];

    % Reverse rounds in reverse order
    for round = n_rounds:-1:1
        pL = pL_chain(round);
        pR = pR_chain(round);
        d  = d_chain(round);

        if d == 1     % was RIGHT expansion: extract from pR+1, restore shift
            pR_mod = find(img == pR | img == pR+1);
            for ii = 1:numel(pR_mod)
                p = img(pR_mod(ii));
                if p == pR+1
                    D_ext(end+1) = 1; img(pR_mod(ii)) = pR; %#ok<AGROW>
                else
                    D_ext(end+1) = 0; %#ok<AGROW>
                end
            end
            % Restore shift: pixels > pR+1 shift back left
            img(img > pR+1) = img(img > pR+1) - 1;
        else          % was LEFT expansion: extract from pL-1, restore shift
            pL_mod = find(img == pL | img == pL-1);
            for ii = 1:numel(pL_mod)
                p = img(pL_mod(ii));
                if p == pL-1
                    D_ext(end+1) = 1; img(pL_mod(ii)) = pL; %#ok<AGROW>
                else
                    D_ext(end+1) = 0; %#ok<AGROW>
                end
            end
            % Restore shift: pixels < pL-1 shift back right
            img(img < pL-1) = img(img < pL-1) + 1;
        end
    end

    % Restore header pixels
    for bi = 1:32
        img(N-32+bi) = bitset(uint8(img(N-32+bi)), 1, 0);
    end

    D_ext = fliplr(D_ext);   % extracted in reverse order
    I_rec = uint8(reshape(img, size(I_emb)));
end

% ==========================================================================
%  METRICS
% ==========================================================================
function p = compute_psnr(I, I_emb)
    mse = mean((double(I(:))-double(I_emb(:))).^2);
    if mse==0, p=Inf; else, p=10*log10(255^2/mse); end
end

% ==========================================================================
%  SYNTHETIC TEST IMAGE GENERATOR
% ==========================================================================
function imgs = generate_test_images()
    imgs = cell(8,1);
    sz = 512;
    % Medical images
    rng(1); I=uint8(ones(sz)*20); cx=sz/2; cy=sz/2;
    for r=1:sz; for c=1:sz
        d=sqrt((r-cx)^2+(c-cy)^2)/(sz*0.35);
        if d<1, I(r,c)=uint8(min(255,80+round(120*exp(-d*2))+randi(20))); end
    end; end
    imgs{1}=I;
    rng(2); I=imgs{1};
    for r=round(sz*0.35):round(sz*0.65); for c=round(sz*0.4):round(sz*0.6)
        d=sqrt((r-cx)^2+(c-cy)^2)/(sz*0.12);
        if d<1, I(r,c)=uint8(max(0,double(I(r,c))-round(60*exp(-d*2)))); end
    end; end
    imgs{2}=I;
    rng(3); I=uint8(zeros(sz));
    for r=1:sz; for c=1:sz
        I(r,c)=uint8(40+randi(20));
        if mod(c,round(sz/8))<round(sz/32), I(r,c)=uint8(min(255,double(I(r,c))+120+randi(30))); end
    end; end
    imgs{3}=I;
    rng(4); I=uint8(ones(sz)*80);
    for r=1:sz; for c=1:sz
        if abs(r-sz/2)<sz/6
            bf=max(0,1-abs(c-sz/2)/(sz*0.3));
            I(r,c)=uint8(min(255,80+round(150*bf)+randi(15)));
        end
    end; end
    imgs{4}=I;
    % Natural images (synthetic approximations)
    rng(5); imgs{5}=uint8(180-round(30*peaks(sz)*5)); imgs{5}=max(0,min(255,imgs{5}));
    rng(6); imgs{6}=uint8(128+round(60*randn(sz))); imgs{6}=max(0,min(255,imgs{6}));
    rng(7); [X,Y]=meshgrid(linspace(0,4*pi,sz));
    imgs{7}=uint8(128+round(127*sin(X).*cos(Y)));
    rng(8); imgs{8}=uint8(100+round(60*randn(sz))); imgs{8}=max(0,min(255,imgs{8}));
end
