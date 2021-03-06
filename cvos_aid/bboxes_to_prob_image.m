%-------------------------------------------------------------------------
% bboxes_to_prob_image
%
% combines the probability generated by each box into one for the object
% over the whole image
%-------------------------------------------------------------------------
function [prob, count] = bboxes_to_prob_image(imsize, boxes, FG, ...
  stub_conf, stub_conf_inter, stub_prob)

n_boxes = size(boxes, 1);
prob = zeros(imsize);
count = zeros(imsize);
rows = imsize(1);
cols = imsize(2);

%-------------------------------------------------------------------------
% parsing inputs
%-------------------------------------------------------------------------
if exist('stub_conf', 'var') && ~isempty(stub_conf);
  bb_conf = stub_conf;
else
  % bb_conf = cat(1, boxes.conf_colour);
  bb_conf = ones(n_boxes, 1); % conf_colour not useful in this fashion
end

if exist('stub_conf_inter', 'var') && ~isempty(stub_conf_inter);
  bb_conf_inter = stub_conf_inter;
else
  % bb_conf = cat(1, boxes.conf_colour);
  bb_conf_inter = ones(n_boxes, 1); % conf_colour not useful in this fashion
end

if ~exist('FG', 'var') || isempty(FG);
  FG = 1;
end

if exist('stub_prob', 'var') && ~isempty(stub_prob);
  bb_prob = stub_prob;
elseif FG == 1;
  bb_prob = cat(3, boxes.fg_prob);
else
  bb_prob = cat(3, boxes.bg_prob);
end

%-------------------------------------------------------------------------
% do work
%-------------------------------------------------------------------------
for k = 1:n_boxes;
  y = round(boxes(k).y);
  x = round(boxes(k).x);
  r = boxes(k).r;
  
  % image
  ymin = max(1,    y - r);
  ymax = min(rows, y + r);
  xmin = max(1,    x - r);
  xmax = min(cols, x + r);
  
  ys = ymin:ymax;
  xs = xmin:xmax;

  % box
  bymin = ymin - y + r + 1;
  bymax = ymax - y + r + 1;
  bxmin = xmin - x + r + 1;
  bxmax = xmax - x + r + 1;
  
  bys = bymin:bymax;
  bxs = bxmin:bxmax;
  
  nbys = length(bys);
  nbxs = length(bxs);
  
  % combine via averaging
  new_prob = prob(ys, xs) + bb_prob(bys, bxs, k) ...
    .* boxes(k).invd(bys, bxs) * bb_conf(k) * bb_conf_inter(k);
  if any(vec(isnan(new_prob)));
    new_prob(isnan(new_prob)) = 0.0;
    fprintf('nans in boxes\n')
  end
  prob(ys, xs) = new_prob;
  count(ys, xs) = count(ys, xs) + boxes(k).invd(bys, bxs) * bb_conf(k);
end

prob = prob ./ count;
prob(count == 0) = 0.0;
end
