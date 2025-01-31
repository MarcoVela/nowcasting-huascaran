using HDF5
using DrWatson
using Random

function read_from_file(path)
  h5read(path, "FED")
end

function read_from_folder(path)
  paths = readdir(path; join=true)
  datasets = read_from_file.(paths)
  cat(datasets...; dims=4)
end

function get_dataset(; splitratio, batchsize, N, path, kwargs...)
  @assert ispath(path) "$path is not a path"
  if isfile(path)
    dataset = read_from_file(path)
  elseif isdir(path)
    dataset = read_from_folder(path)
  end

  @info "split"
  TOTAL_SAMPLES = size(dataset, 4)
  TOTAL_FRAMES = size(dataset, 5)
  last_train_sample_index = ceil(Int, TOTAL_SAMPLES * splitratio)
  dataset_train = view(dataset, :, :, :, 1:last_train_sample_index, :)
  dataset_test = view(dataset, :, :, :, last_train_sample_index+1:TOTAL_SAMPLES, :)


  @info "rotating dataset"
  ds = dataset_train
  n = size(ds, 4)
  dataset_train = zeros(eltype(ds), size(ds)[1:3]..., n*4, size(ds, 5))
  Random.seed!(42)
  idx = shuffle(axes(dataset_train, 4))
  dataset_train[:,:,:,idx[1:n],:] = ds
  for i in 1:3
    @info "rotation" i
    dataset_train[:,:,:,idx[n*i+1:n*(i+1)],:] = mapslices(Base.Fix2(rotr90, i), ds, dims=(1,2))
  end
  ds = nothing
  GC.gc()



  x_train = (copy(view(dataset_train, :, :, :, t:t+batchsize-1, 1:N)) for t in 1:batchsize:size(dataset_train, 4)-batchsize+1)
  y_train = (copy(view(dataset_train, :, :, :, t:t+batchsize-1, N+1:TOTAL_FRAMES)) for t in 1:batchsize:size(dataset_train, 4)-batchsize+1)
  train_data = zip(x_train, y_train)

  x_test = (copy(view(dataset_test, :, :, :, t:t+batchsize-1, 1:N)) for t in 1:batchsize:size(dataset_test, 4)-batchsize+1)
  y_test = (copy(view(dataset_test, :, :, :, t:t+batchsize-1, N+1:TOTAL_FRAMES)) for t in 1:batchsize:size(dataset_test, 4)-batchsize+1)
  test_data = zip(x_test, y_test)

  train_data, test_data
end
