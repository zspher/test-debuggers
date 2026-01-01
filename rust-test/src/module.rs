pub struct Square(pub u32, pub u32);

impl Square {
    pub fn area(&self) -> u32 {
        self.0 * self.1
    }
}

pub fn test(sq: Square) {
    println!("this is a test");
    sq.area();
}
