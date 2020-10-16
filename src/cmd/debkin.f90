program main
  use flag, only: flgget
  use num_env, only: swap
  use ssat_env, only: alert, fatal
  implicit none

  character(len=255) :: input, msg, param, usage
  real :: drag, depth(2)
  real, allocatable :: arr(:, :)
  integer :: err, i, id, m, n
  character :: c

  usage = 'usage: debkin [-ddrag] -zT|Bdepth -Pprofile'
  drag = 0
  depth = 0
  do while(flgget(param, c))
    select case(c)
    case('d')
      read(param, *) drag
    case('z')
      if(flgget(param, c, .true.)) call fatal(usage)
      select case(c)
      case('T')
        read(param, *) depth(2)
      case('B')
        read(param, *) depth(1)
      case default
        call fatal(usage)
      end select
    case('P')
      input = param
    case default
      call fatal(usage)
    end select
  end do
  if(len_trim(input) == 0 .or. depth(1) <= depth(2)) call fatal(usage)

  open(newunit=id, file=input, status='old', iostat=err, iomsg=msg)
  if(err /= 0) call fatal(msg)
  read(id, *, iostat=err, iomsg=msg) m, n
  if(err /= 0) call fatal(msg)
  n = n + 1
  allocate(arr(2+n, m))
  read(id, *, iostat=err, iomsg=msg) (arr(:1+n, i), i = 1, m)
  if(err /= 0) call fatal(msg)
  close(id)
  call debkin(arr(1, :), arr(1+n, :), arr(2+n, :))
  print '(I5,1X,I5)', m, n
  do i = 1, m
    print '(*(F7.2))', arr(:, i)
  end do
  deallocate(arr)
  stop

contains
  subroutine debkin(x, y1, y2)
    real, intent(in) :: x(:), y1(:)
    real, intent(out) :: y2(:)
    real :: alpha, h, k(size(y2)), s
    integer :: i, j, n

    n = size(x)
    i = minloc(y1, 1)
    if(drag == 0) then
      j = maxloc(y1, 1)
      h = y1(j) - y1(i)
      s = sqrt((x(j) - x(i))**2 + h**2)
      alpha = asin(h / s)
      drag = h / (2. * cos(alpha) * s)
      write(msg, '(A5,1X,F9.4)') 'DRAG:', drag
      call alert(msg)
    end if
    k = kin_(x, y1, drag, 1) + kin_(x, y1, drag, -1)
    k = k / maxval(k)
    if(k(i) /= 1) call fatal('invalid drag.')
    y2 = y1 - k * (depth(1) - depth(2)) + depth(2)
  end subroutine

  pure function kin_(x, y, crr, dir) result(r)
    real, intent(in) :: x(:), y(:), crr
    integer, intent(in) :: dir
    real :: alpha, h, r(size(x)), s
    integer :: e1, e2, e3, i, ii, j, jj

    e1 = 2
    e2 = size(x)
    e3 = dir
    if(dir < 0) call swap(e1, e2)
    r = 0
    do i = e1, e2, e3
      j = i - 1
      h = dir * (y(j) - y(i))
      s = sqrt((x(i) - x(j))**2 + h**2)
      alpha = asin(h / s)
      ii = i
      jj = j
      if(dir < 0) call swap(ii, jj)
      r(ii) = max(0., h + r(jj) - crr * cos(alpha) * s)
    end do
  end function
end program