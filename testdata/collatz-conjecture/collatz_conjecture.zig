pub const ComputationError = error{IllegalArgument};

pub fn steps(number: usize) ComputationError!usize {
    var i: usize = 0;
    if (number == 0) {
        return ComputationError.IllegalArgument;
    }

    var n = number;
    while (n != 1) {
        if (n % 2 == 0) {
            n /= 2;
        } else {
            n = 3 * n + 1;
        }
        i += 1;
    }
    return i;
}