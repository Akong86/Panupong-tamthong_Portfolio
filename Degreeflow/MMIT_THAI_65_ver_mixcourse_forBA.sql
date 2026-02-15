-- =========================================================
-- 1. SETUP DATABASE
-- =========================================================
DROP DATABASE IF EXISTS cmu_curriculum_global;
CREATE DATABASE cmu_curriculum_global CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cmu_curriculum_global;

-- =========================================================
-- 2. CREATE TABLES (โครงสร้างตาม Requirement เพื่อนเป๊ะๆ)
-- =========================================================

-- 2.1 ตารางประเภทวิชา (CourseTypes)
CREATE TABLE CourseTypes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name_en VARCHAR(50) NOT NULL,
    name_th VARCHAR(50) NOT NULL
);

-- 2.2 ตารางหลักสูตร
CREATE TABLE Curriculums (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(10) UNIQUE, 
    name_th VARCHAR(200),
    name_en VARCHAR(200),
    faculty_name VARCHAR(200) DEFAULT 'วิทยาลัยศิลปะ สื่อ และเทคโนโลยี (CAMT)'
);

-- 2.3 ตารางรายวิชา (Courses_MMIT_65) 
-- เพิ่ม description_th, description_en และ type_id ตามขอ
CREATE TABLE Courses_MMIT_65 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(15) UNIQUE, 
    name_th VARCHAR(255), 
    name_en VARCHAR(255), 
    credit_val INT DEFAULT 3,      -- หน่วยกิตรวม
    lecture_hours INT DEFAULT 0,   -- (2) ชั่วโมงบรรยาย
    lab_hours INT DEFAULT 0,       -- (2) ชั่วโมงแล็บ
    self_study_hours INT DEFAULT 0,-- (5) ชั่วโมงค้นคว้า
    description_th TEXT, 
    description_en TEXT, 
    type_id INT,         
    FOREIGN KEY (type_id) REFERENCES CourseTypes(id)
);

-- 2.4 ตารางทักษะ (Skills)
CREATE TABLE Skills (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name_th VARCHAR(255), -- เพิ่มความยาวเผื่อชื่อยาวๆ
    name_en VARCHAR(255),
    category ENUM('Hard Skill', 'Soft Skill') DEFAULT 'Hard Skill',
    description TEXT      -- (เผื่ออยากใส่นิยามเพิ่มเติม)
);

-- 2.5 ตารางเชื่อมวิชา-ทักษะ (Course_Skills)
-- นี่คือจุดสำคัญ! ทำให้ 1 วิชา มีได้หลายสกิล
CREATE TABLE Course_Skills (
    course_code VARCHAR(15),
    skill_id INT,
    PRIMARY KEY (course_code, skill_id),
    FOREIGN KEY (course_code) REFERENCES Courses_MMIT_65(code),
    FOREIGN KEY (skill_id) REFERENCES Skills(id)
);

-- 2.6 ตารางอาชีพ (Career_Paths)
CREATE TABLE Career_Paths (
    id INT PRIMARY KEY AUTO_INCREMENT,
    curriculum_code VARCHAR(10), 
    name_th VARCHAR(200),
    name_en VARCHAR(200),
    description TEXT,
    FOREIGN KEY (curriculum_code) REFERENCES Curriculums(code)
);

-- 2.7 ตาราง Roadmap (Career_Roadmaps)
CREATE TABLE Career_Roadmaps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    career_id INT,
    course_code VARCHAR(15), 
    skill_id INT, -- <--- คอลัมน์นี้ต้องมี ถึงจะสร้าง View ได้
    importance ENUM('Essential', 'Recommended', 'Optional') DEFAULT 'Recommended',
    
    FOREIGN KEY (career_id) REFERENCES Career_Paths(id),
    FOREIGN KEY (course_code) REFERENCES Courses_MMIT_65(code),
    FOREIGN KEY (skill_id) REFERENCES Skills(id)
);

-- 2.8 ตารางแผนการเรียน (Study_Plan_Structures)
CREATE TABLE Study_Plan_Structures (
    id INT PRIMARY KEY AUTO_INCREMENT,
    curriculum_code VARCHAR(10), 
    year_level INT, 
    semester INT,
    course_code VARCHAR(15) NULL, 
    type_id INT,  -- <--- ต้องเพิ่มบรรทัดนี้ก่อนครับ ถึงจะทำ FK ข้างล่างได้
    name_th VARCHAR(200),
    name_en VARCHAR(200),
    remark_th VARCHAR(255),
    remark_en VARCHAR(255),
    FOREIGN KEY (curriculum_code) REFERENCES Curriculums(code),
    FOREIGN KEY (course_code) REFERENCES Courses_MMIT_65(code),
    FOREIGN KEY (type_id) REFERENCES CourseTypes(id)
);
-- 2.9 ตารางวิชาตัวต่อ (Prerequisites_MMIT_65)
CREATE TABLE Prerequisites_MMIT_65 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_code VARCHAR(15),
    prereq_course_code VARCHAR(15),
    FOREIGN KEY (course_code) REFERENCES Courses_MMIT_65(code),
    FOREIGN KEY (prereq_course_code) REFERENCES Courses_MMIT_65(code)
);

-- 2.10 ตารางผู้ใช้งาน (Users)
CREATE TABLE Users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('Student', 'Admin', 'Staff') NOT NULL,
    full_name VARCHAR(200),
    curriculum_code VARCHAR(10),
    FOREIGN KEY (curriculum_code) REFERENCES Curriculums(code)
);

-- 2.11 ตารางความคืบหน้า (Student_Progress)
CREATE TABLE Student_Progress (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    course_code VARCHAR(15),
    status ENUM('Not_Started', 'In_Progress', 'Completed', 'Failed') DEFAULT 'Not_Started',
    grade VARCHAR(2),
    semester_taken VARCHAR(10),
    FOREIGN KEY (user_id) REFERENCES Users(id),
    FOREIGN KEY (course_code) REFERENCES Courses_MMIT_65(code)
);
-- สร้างตารางเก็บ Skill แยกตามอาชีพ
CREATE TABLE Career_Skills (
    id INT PRIMARY KEY AUTO_INCREMENT,
    career_id INT NOT NULL,
    skill_id INT NOT NULL,
    importance ENUM('Essential', 'Recommended', 'Optional') DEFAULT 'Essential',
    
    -- เชื่อมกับตาราง Career_Paths และ Skills ที่คุณมีอยู่เดิม
    FOREIGN KEY (career_id) REFERENCES Career_Paths(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES Skills(id) ON DELETE CASCADE,
    
    -- ป้องกันข้อมูลซ้ำ (1 อาชีพ ไม่ควรมี Skill เดิมซ้ำ 2 บรรทัด)
    UNIQUE (career_id, skill_id)
);
-- =========================================================
-- 3. INSERT DATA: Meta Data
-- =========================================================

-- 3.1 Course Types
INSERT INTO CourseTypes (id, name_en, name_th) VALUES
(1, 'General Education', 'หมวดวิชาศึกษาทั่วไป'),
(2, 'Core Course', 'วิชาแกน'),
(3, 'Major Required', 'วิชาเอกบังคับ'),
(4, 'Major Elective', 'วิชาเอกเลือก'),
(5, 'Free Elective', 'วิชาเลือกเสรี');

-- 3.2 Skills (จัดเต็ม)
INSERT INTO Skills (name_th, name_en, category) VALUES
-- Tech Skills (เจาะลึกรายวิชา)
('การเขียนโปรแกรมพื้นฐานและอัลกอริทึม', 'Fundamental Programming & Algorithms', 'Hard Skill'),
('การเขียนโปรแกรมเชิงวัตถุ (OOP)', 'Object-Oriented Programming (OOP)', 'Hard Skill'),
('การพัฒนาเว็บแอปพลิเคชัน (Full-stack)', 'Web Application Development (Full-stack)', 'Hard Skill'),
('การพัฒนาเว็บฝั่งลูกข่าย (Frontend)', 'Client-side Web Development', 'Hard Skill'),
('การพัฒนาเว็บเซอร์วิสและ API', 'Web Services & API Development', 'Hard Skill'),
('การออกแบบและจัดการฐานข้อมูล', 'Database Design & Management', 'Hard Skill'),
('การทำเหมืองข้อมูลและการวิเคราะห์', 'Data Mining & Analysis', 'Hard Skill'),
('การแสดงภาพข้อมูลทางธุรกิจ', 'Business Data Visualization', 'Hard Skill'),
('การพัฒนาแอปพลิเคชันมือถือ', 'Mobile Application Development', 'Hard Skill'),
('ความปลอดภัยเครือข่ายและไซเบอร์', 'Network & Cyber Security', 'Hard Skill'),
('เทคโนโลยีคลาวด์และการประมวลผล', 'Cloud Computing Technology', 'Hard Skill'),
('ระบบ ERP และกระบวนการธุรกิจ', 'ERP Systems & Business Processes', 'Hard Skill'),
('การกำหนดค่าระบบ ERP (Configuration)', 'ERP System Configuration', 'Hard Skill'),
('การเขียนโปรแกรมส่วนขยาย ERP (ABAP)', 'ERP Programming (ABAP)', 'Hard Skill'),
('แบบจำลองกระบวนการธุรกิจ (BPMN)', 'Business Process Modeling (BPMN)', 'Hard Skill'),
('พาณิชย์อิเล็กทรอนิกส์และการตลาดดิจิทัล', 'E-Commerce & Digital Marketing', 'Hard Skill'),
('การสร้างสรรค์คอนเทนต์มัลติมีเดีย', 'Multimedia Content Creation', 'Hard Skill'),
('การจัดการโซ่อุปทานดิจิทัล', 'Digital Supply Chain Management', 'Hard Skill'),
('ระเบียบวิธีวิจัยทางไอที', 'IT Research Methodology', 'Hard Skill'),
('การจัดการแบบลีน', 'Lean Management', 'Hard Skill'),
('เทคโนโลยีโลจิสติกส์', 'Logistics Technology', 'Hard Skill'),
('การบริหารงานบำรุงรักษา', 'Maintenance Management', 'Hard Skill'),
('การจำลองสถานการณ์โลจิสติกส์', 'Logistics Simulation', 'Hard Skill'), -- <--- ใส่คอมม่าตรงนี้ครับ
('ตรรกะทางธุรกิจและการเริ่มธุรกิจ', 'Business Logic & Startup', 'Hard Skill'),
('การบริหารจัดการความสัมพันธ์ลูกค้า (CRM)', 'Customer Relationship Management (CRM)', 'Soft Skill'),
('การบัญชีและการเงินพื้นฐาน', 'Basic Accounting & Finance', 'Hard Skill'),
('การบริหารทรัพยากรมนุษย์', 'HR Management', 'Hard Skill'),
('การจัดการความรู้', 'Knowledge Management', 'Hard Skill'),
('คณิตศาสตร์', 'Mathematics', 'Hard Skill'),
('ภาษาอังกฤษเพื่อการสื่อสาร', 'English Communication', 'Soft Skill'),
('ระเบียบวิธีวิจัย', 'Research Methodology', 'Hard Skill'),
('พื้นฐานไอทีและคอมพิวเตอร์', 'IT Fundamentals', 'Hard Skill'),
('เทคโนโลยีการท่องเที่ยว', 'Tourism Technology', 'Hard Skill'),
('การจัดการงานอีเวนต์ดิจิทัล', 'Digital Event Management', 'Hard Skill'),
('ศิลปะและการออกแบบดิจิทัล', 'Digital Art & Design', 'Hard Skill'),
('เทคโนโลยีเครือข่าย', 'Network Technology', 'Hard Skill'),
('การเป็นพลเมืองดิจิทัล', 'Digital Citizenship', 'Soft Skill'),
('จิตวิทยาและการบริการ', 'Psychology & Service', 'Soft Skill'),
('การจัดการนวัตกรรม', 'Innovation Management', 'Hard Skill');

INSERT INTO Curriculums (code, name_th, name_en) 
VALUES ('MMIT', 'การจัดการสมัยใหม่และเทคโนโลยีสารสนเทศ', 'Modern Management and Information Technology');
-- =========================================================
-- 4. INSERT COURSES (Complete List with Descriptions & Type ID)
-- =========================================================


-- =========================================================
-- SCRIPT: INSERT COMPLETE COURSE DATA (GRANULAR & DESCRIBED)
-- Purpose: Populates the Courses_MMIT_65 table with detailed
--          credit structures (L-L-S) and full descriptions.
-- =========================================================


-- Insert Data: (code, th, en, credit, lec, lab, self, type, desc_th, desc_en)
INSERT INTO Courses_MMIT_65 
(code, name_th, name_en, credit_val, lecture_hours, lab_hours, self_study_hours, type_id, description_th, description_en) 
VALUES

-- -----------------------------------------------------------------------------------------
-- [Type 1] หมวดวิชาศึกษาทั่วไป (General Education)
-- -----------------------------------------------------------------------------------------
('001101', 'ภาษาอังกฤษพื้นฐาน 1', 'Fundamental English 1', 3, 3, 0, 6, 1, 
 'การฝึกทักษะการฟัง พูด อ่าน และเขียนภาษาอังกฤษในชีวิตประจำวัน เน้นการสื่อสารเบื้องต้นและการใช้ไวยากรณ์พื้นฐาน', 
 'Practice listening, speaking, reading and writing English in daily life context, focusing on basic communication and grammar.'),

('001102', 'ภาษาอังกฤษพื้นฐาน 2', 'Fundamental English 2', 3, 3, 0, 6, 1, 
 'การพัฒนาทักษะภาษาอังกฤษต่อเนื่องจากวิชา 001101 เน้นการสื่อสารที่ซับซ้อนขึ้น การอ่านจับใจความและการเขียนย่อหน้า', 
 'Further development of English skills continuing from 001101, emphasizing complex communication, reading comprehension, and paragraph writing.'),

('001201', 'การอ่านเชิงวิเคราะห์และการเขียน', 'Critical Reading and Effective Writing', 3, 3, 0, 6, 1, 
 'การพัฒนาทักษะการอ่านเชิงวิเคราะห์และการเขียนอย่างมีประสิทธิผล การจับประเด็นสำคัญ การตีความ และการเขียนเชิงวิชาการ', 
 'Development of critical reading and effective writing skills, identifying main ideas, interpretation, and academic writing.'),

('001229', 'ภาษาอังกฤษสำหรับศิลปะสื่อ', 'English for Media Arts', 3, 3, 0, 6, 1, 
 'การใช้ภาษาอังกฤษในบริบทของศิลปะสื่อ การอ่านและวิเคราะห์สื่อสิ่งพิมพ์และสื่อดิจิทัล การนำเสนองานทางสื่อ', 
 'Using English in the context of media arts, reading and analyzing print and digital media, and presenting media works.'),

('140104', 'การเป็นพลเมือง', 'Citizenship', 3, 3, 0, 6, 1, 
 'ความเป็นพลเมืองในระบอบประชาธิปไตย, สิทธิมนุษยชน, กฎหมายรัฐธรรมนูญเบื้องต้น, การมีส่วนร่วมทางการเมือง, ความรับผิดชอบต่อสังคม', 
 'Democratic Citizenship, Human Rights, Basic Constitutional Law, Political Participation, Social Responsibility'),

('204100', 'เทคโนโลยีสารสนเทศและชีวิตสมัยใหม่', 'IT and Modern Life', 3, 3, 0, 6, 1, 
 'บทบาทและความสำคัญของเทคโนโลยีสารสนเทศในชีวิตประจำวัน ความปลอดภัยไซเบอร์ กฎหมายและจริยธรรมทางคอมพิวเตอร์', 
 'Role and importance of Information Technology in daily life, cyber security, computer laws, and digital ethics.'),

-- GE Electives (Standard Structure assumed: 3(3-0-6) for lectures, 1(0-3-1) for activities)
('057122', 'ว่ายน้ำเพื่อชีวิตและการออกกำลังกาย', 'Swimming for Life and Exercise', 1, 0, 3, 1, 1, NULL, NULL),
('057127', 'แบดมินตันเพื่อชีวิตและการออกกำลังกาย', 'Badminton for Life and Exercise', 1, 0, 3, 1, 1, NULL, NULL),
('011269', 'ปรัชญาเศรษฐกิจพอเพียง', 'Philosophy of Sufficiency Economy', 3, 3, 0, 6, 1, NULL, NULL),
('702101', 'การเงินในชีวิตประจำวัน', 'Finance for Daily Life', 3, 3, 0, 6, 1, NULL, NULL),
('009103', 'การรู้สารสนเทศและการนำเสนอสารสนเทศ', 'Information Literacy and Presentation', 3, 3, 0, 6, 1, NULL, NULL),
('176104', 'สิทธิและหน้าที่พลเมืองในยุคดิจิทัล', 'Civic Rights and Duties in Digital Age', 3, 3, 0, 6, 1, NULL, NULL),
('851100', 'การสื่อสารเบื้องต้น', 'Introduction to Communication', 3, 3, 0, 6, 1, NULL, NULL),
('888102', 'อภิมหาข้อมูลเพื่อธุรกิจ', 'Big Data for Business', 3, 2, 2, 5, 1, NULL, NULL),
('953111', 'ซอฟต์แวร์ในชีวิตประจำวัน', 'Software for Everyday Life', 3, 2, 2, 5, 1, NULL, NULL),
('012173', 'ศาสนาเบื้องต้น', 'Descriptive Study of Religion', 3, 3, 0, 6, 1, NULL, NULL),
('050104', 'มนุษย์กับโลกสมัยใหม่', 'Man and the Modern World', 3, 3, 0, 6, 1, NULL, NULL),
('176100', 'กฎหมายและโลกสมัยใหม่', 'Law and Modern World', 3, 3, 0, 6, 1, NULL, NULL),
('201116', 'วิทยาศาสตร์และภาวะโลกร้อน', 'Science and Global Warming', 3, 3, 0, 6, 1, NULL, NULL),
('201190', 'การคิดอย่างมีวิจารณญาณ', 'Critical Thinking', 3, 3, 0, 6, 1, NULL, NULL),
('204123', 'วิทยาการข้อมูลเบื้องต้น', 'Introduction to Data Science', 3, 2, 2, 5, 1, NULL, NULL),
('368100', 'การเริ่มต้นธุรกิจเกษตร', 'Starting an Agribusiness', 3, 3, 0, 6, 1, NULL, NULL),
('603200', 'บรรจุภัณฑ์ในชีวิตประจำวัน', 'Packaging in Daily Life', 3, 3, 0, 6, 1, NULL, NULL),
('610112', 'นวัตกรรมผลิตภัณฑ์อาหาร', 'Food Product Innovation', 3, 3, 0, 6, 1, NULL, NULL),
('888107', 'การเริ่มต้นธุรกิจบนดิจิทัลแพลตฟอร์ม', 'Business Startup on Digital Platform', 3, 2, 2, 5, 1, NULL, NULL),
('159151', 'สังคมและวัฒนธรรมล้านนา', 'Lanna Society and Culture', 3, 3, 0, 6, 1, NULL, NULL),
('154104', 'การอนุรักษ์สิ่งแวดล้อม', 'Environmental Conservation', 3, 3, 0, 6, 1, NULL, NULL),
('201192', 'ดอยสุเทพศึกษา', 'Doi Suthep Studies', 1, 0, 3, 1, 1, NULL, NULL),
('951100', 'ชีวิตสมัยใหม่กับแอนนิเมชัน', 'Modern Life and Animation', 3, 2, 2, 5, 1, NULL, NULL),
('050113', 'ท้องถิ่นในกระแสโลกาภิวัตน์', 'Locality in Globalization', 3, 3, 0, 6, 1, NULL, NULL),
('103271', 'สังคีตวิจักษ์', 'Music Appreciation', 3, 3, 0, 6, 1, NULL, NULL),
('109100', 'มนุษย์กับศิลปะ', 'Man and Art', 3, 3, 0, 6, 1, NULL, NULL),
('109115', 'ชีวิตกับสุนทรียะ', 'Life and Aesthetics', 3, 3, 0, 6, 1, NULL, NULL),
('127100', 'การเมืองในชีวิตประจำวัน', 'Politics in Everyday Life', 3, 3, 0, 6, 1, NULL, NULL),
('154100', 'ภูมิศาสตร์เบื้องต้น', 'Introduction to Geography', 3, 3, 0, 6, 1, NULL, NULL),
('357110', 'แมลงกับมนุษยชาติ', 'Insects and Mankind', 3, 3, 0, 6, 1, NULL, NULL),
('602102', 'ชีวิตกับพลังงานทางเลือก', 'Life and Alternative Energy', 3, 3, 0, 6, 1, NULL, NULL),

-- -----------------------------------------------------------------------------------------
-- [Type 2] วิชาแกน (Core Courses)
-- -----------------------------------------------------------------------------------------
('206171', 'คณิตศาสตร์ทั่วไป 1', 'General Mathematics 1', 3, 3, 0, 6, 2, 
 'ตรรกศาสตร์ เซต ฟังก์ชัน เรขาคณิตวิเคราะห์ ลิมิตและความต่อเนื่อง อนุพันธ์และการประยุกต์ อินทิเกรตเบื้องต้น', 
 'Logic, sets, functions, analytic geometry, limits and continuity, derivatives and applications, introduction to integration.'),

('208263', 'สถิติเบื้องต้น', 'Elementary Statistics', 3, 3, 0, 6, 2, 
 'สถิติพรรณนา ความน่าจะเป็น ตัวแปรสุ่มและการแจกแจงความน่าจะเป็น การประมาณค่าและการทดสอบสมมติฐาน', 
 'Descriptive statistics, probability, random variables and probability distributions, estimation and hypothesis testing.'),

('208262', 'สถิติเบื้องต้นสำหรับวิทยาศาสตร์และเทคโนโลยี', 'Elementary Statistics for Science and Technology', 3, 3, 0, 6, 2, 
 'ความรู้เบื้องต้นทางสถิติ การวิเคราะห์ข้อมูล การแจกแจงความน่าจะเป็น การทดสอบสมมติฐานสำหรับงานทางวิทยาศาสตร์', 
 'Introduction to statistics, data analysis, probability distributions, hypothesis testing for science and technology.'),

('954140', 'พื้นฐานไอที', 'IT Literacy', 3, 3, 0, 6, 2, 
 'ความรู้พื้นฐานเกี่ยวกับระบบคอมพิวเตอร์ ฮาร์ดแวร์ ซอฟต์แวร์ เครือข่ายคอมพิวเตอร์ และการประยุกต์ใช้ในชีวิตประจำวัน', 
 'Basic knowledge of computer systems, hardware, software, computer networks, and daily life applications.'),

('954142', 'เขียนโปรแกรมพื้นฐาน', 'Fund. Programming', 3, 2, 2, 5, 2, 
 'หลักการเขียนโปรแกรม โครงสร้างภาษา การแก้ปัญหาด้วยอัลกอริทึม ผังงาน และการเขียนโปรแกรมเบื้องต้น (เช่น Python/C)', 
 'Programming principles, language structure, problem solving with algorithms, flowcharts, and basic programming (e.g., Python/C).'),

('954143', 'การจัดการข้อมูล', 'Data Management', 3, 2, 2, 5, 2, 
 'แนวคิดระบบฐานข้อมูล การจัดการข้อมูลในองค์กร วงจรชีวิตข้อมูล และความปลอดภัยของข้อมูล', 
 'Database concepts, data management in organizations, data lifecycle, and data security.'),

('954170', 'แบบจำลองธุรกิจ', 'Business Process Modeling', 3, 2, 2, 5, 2, 
 'การวิเคราะห์และเขียนแผนผังกระบวนการธุรกิจ (BPMN) การปรับปรุงกระบวนการ และการจัดการกระบวนการธุรกิจ', 
 'Analysis and modeling of business processes (BPMN), process improvement, and business process management.'),

('954230', 'การติดตามทางการเงิน', 'Financial Tracking', 3, 3, 0, 6, 2, 
 'หลักการบัญชีเบื้องต้น การอ่านและวิเคราะห์งบการเงิน และการใช้เครื่องมือดิจิทัลช่วยจัดการการเงินส่วนบุคคลและธุรกิจ', 
 'Basic accounting principles, reading and analyzing financial statements, and using digital tools for personal and business financial management.'),

('954231', 'การจัดการทุนมนุษย์', 'Human Capital Management', 3, 3, 0, 6, 2, 
 'การบริหารทรัพยากรบุคคล การสรรหา การคัดเลือก การพัฒนาบุคลากร และการรักษาบุคลากรในยุคดิจิทัล', 
 'Human resource management, recruitment, selection, personnel development, and retention in the digital age.'),

('954241', 'คำนวณศิลป์', 'Art of Computing', 3, 2, 2, 5, 2, 
 'หลักการออกแบบกราฟิก (Design Principles), ทฤษฎีสี, กราฟิกแบบ Raster vs Vector, การใช้โปรแกรมตกแต่งภาพ (Photoshop/Illustrator)', 
 'Design Principles, Color Theory, Raster vs Vector, Image Editing Software Usage'),

('954248', 'เทคโนโลยีสารสนเทศและการสื่อสาร', 'ICT', 3, 3, 0, 6, 2, 
 'แบบจำลอง OSI Model, โปรโตคอล TCP/IP, โทโพโลยีเครือข่าย, การจัดสรร IP Address, พื้นฐานความปลอดภัยเครือข่าย, เทคโนโลยีไร้สาย (Wi-Fi/5G)', 
 'OSI Model, TCP/IP Protocols, Network Topologies, IP Addressing, Basic Network Security, Wireless Technologies'),

-- -----------------------------------------------------------------------------------------
-- [Type 3] วิชาเอกบังคับ (Major Required)
-- -----------------------------------------------------------------------------------------
('954100', 'ระบบสารสนเทศองค์กร', 'IS for Organization', 3, 3, 0, 6, 3, 
 'ความรู้เบื้องต้นเกี่ยวกับระบบสารสนเทศในองค์กร ประเภทของระบบสารสนเทศ และกลยุทธ์การใช้ไอทีเพื่อความได้เปรียบทางธุรกิจ', 
 'Introduction to information systems in organizations, types of IS, and IT strategies for business competitive advantage.'),

('954244', 'วิเคราะห์และออกแบบระบบ', 'System Analysis and Design', 3, 3, 0, 6, 3, 
 'วงจรการพัฒนาระบบ (SDLC) การรวบรวมความต้องการ การวิเคราะห์และออกแบบระบบโดยใช้ UML', 
 'System Development Life Cycle (SDLC), requirement gathering, system analysis and design using UML.'),

('954246', 'เขียนโปรแกรมขั้นสูง', 'Adv. Programming', 3, 2, 2, 5, 3, 
 'การเขียนโปรแกรมเชิงวัตถุ (OOP) คลาส วัตถุ การสืบทอด และการจัดการข้อผิดพลาด (Exception Handling)', 
 'Object-Oriented Programming (OOP), classes, objects, inheritance, and exception handling.'),

('954310', 'ระบบ ERP', 'Enterprise Resource Planning', 3, 3, 0, 6, 3, 
 'หลักการของระบบวางแผนทรัพยากรองค์กร (ERP) การบูรณาการกระบวนการธุรกิจหลัก และการใช้งานซอฟต์แวร์ ERP', 
 'Principles of Enterprise Resource Planning (ERP) systems, integration of core business processes, and ERP software usage.'),

('954340', 'ออกแบบฐานข้อมูลองค์กร', 'Enterprise DB Design', 3, 2, 2, 5, 3, 
 'การออกแบบฐานข้อมูลระดับองค์กร แบบจำลองข้อมูลเชิงสัมพันธ์ (Relational Model) การทำ Normalization และภาษา SQL', 
 'Enterprise database design, Relational Model, Normalization, and SQL language.'),

('954346', 'การพัฒนาแอปธุรกิจ', 'Business App Dev', 3, 2, 2, 5, 3, 
 'การพัฒนาแอปพลิเคชันเพื่อตอบโจทย์ทางธุรกิจ การเชื่อมต่อฐานข้อมูล และการออกแบบส่วนติดต่อผู้ใช้ (UX/UI)', 
 'Application development for business solutions, database connectivity, and User Interface/User Experience (UX/UI) design.'),

('954365', 'การจัดการความรู้', 'Knowledge Management', 3, 3, 0, 6, 3, 
 'แนวคิดและกระบวนการจัดการความรู้ การจัดเก็บ การแบ่งปัน และการประยุกต์ใช้ความรู้เพื่อเพิ่มประสิทธิภาพองค์กร', 
 'Concepts and processes of Knowledge Management (KM), storage, sharing, and application of knowledge for organizational efficiency.'),

('954370', 'การจัดการวัสดุ', 'Material Management', 3, 3, 0, 6, 3, 
 'การบริหารจัดการวัสดุคงคลัง การจัดซื้อ การตรวจรับ และการควบคุมวัสดุในระบบอุตสาหกรรมและบริการ', 
 'Inventory material management, purchasing, receiving, and material control in industrial and service systems.'),

('954374', 'การขายและการจัดจำหน่าย', 'Sales & Distribution', 3, 3, 0, 6, 3, 
 'กระบวนการขาย ช่องทางการจัดจำหน่าย การจัดการคำสั่งซื้อ และโลจิสติกส์ขาออก', 
 'Sales processes, distribution channels, order management, and outbound logistics.'),

('954381', 'เตรียมความพร้อมฝึกงาน', 'Prep for WIL', 3, 3, 0, 6, 3, 
 'การเตรียมความพร้อมก่อนออกปฏิบัติงานสหกิจศึกษา การเขียนจดหมายสมัครงาน การสัมภาษณ์ และบุคลิกภาพ', 
 'Preparation for Work-Integrated Learning (WIL), resume writing, job interviewing, and personality development.'),

('954416', 'โซ่อุปทานและลูกค้าสัมพันธ์', 'Supply Chain & CRM', 3, 3, 0, 6, 3, 
 'การจัดการห่วงโซ่อุปทาน (SCM) และการบริหารความสัมพันธ์ลูกค้า (CRM) เพื่อสร้างมูลค่าเพิ่มให้ธุรกิจ', 
 'Supply Chain Management (SCM) and Customer Relationship Management (CRM) to create business value.'),

('954484', 'สหกิจศึกษา 1', 'WIL 1', 6, 0, 18, 0, 3, 
 'การปฏิบัติงานจริงในสถานประกอบการ ระยะที่ 1 เพื่อเรียนรู้กระบวนการทำงานและวัฒนธรรมองค์กร', 
 'Actual work experience in an organization, Phase 1, to learn work processes and organizational culture.'),

('954485', 'สหกิจศึกษา 2', 'WIL 2', 6, 0, 18, 0, 3, 
 'การปฏิบัติงานจริงในสถานประกอบการ ระยะที่ 2 เน้นการทำโครงงานหรือการแก้ปัญหาในการทำงาน', 
 'Actual work experience in an organization, Phase 2, focusing on projects or work-related problem solving.'),

('954490', 'ระเบียบวิธีวิจัยไอที', 'Research Methodology', 3, 3, 0, 6, 3, 
 'ระเบียบวิธีวิจัยทางเทคโนโลยีสารสนเทศ การกำหนดปัญหาวิจัย การเก็บรวบรวมข้อมูล และการวิเคราะห์ผล', 
 'Research methodology in Information Technology, defining research problems, data collection, and analysis.'),

-- -----------------------------------------------------------------------------------------
-- [Type 4] วิชาเอกเลือก (Major Electives)
-- -----------------------------------------------------------------------------------------
('954240', 'การเขียนโปรแกรมเว็บ', 'Web Programming', 3, 2, 2, 5, 4, 
 'การพัฒนาเว็บแอปพลิเคชัน ฝั่ง Client (HTML, CSS, JavaScript) และฝั่ง Server', 
 'Web application development, Client-side (HTML, CSS, JavaScript) and Server-side programming.'),

('954316', 'เทคโนโลยีในโซ่อุปทาน', 'Supply Chain Tech', 3, 3, 0, 6, 4, 
 'การประยุกต์ใช้เทคโนโลยีสารสนเทศในการจัดการห่วงโซ่อุปทาน และระบบติดตามสินค้า', 
 'Application of IT in Supply Chain Management and tracking systems.'),

('954321', 'การดำเนินงานบริการอิเล็กทรอนิกส์', 'Ops for E-Service', 3, 3, 0, 6, 4, 
 'การจัดการการดำเนินงานและการบริการสำหรับธุรกิจบริการดิจิทัล', 
 'Operations and service management for digital service businesses.'),

('954322', 'เทคโนโลยีศูนย์บริการ', 'Call Center Tech', 3, 3, 0, 6, 4, 
 'ระบบตอบรับอัตโนมัติ (IVR), เทคโนโลยี VoIP, การบริหารจัดการคิว (Queue Management), การบูรณาการ CRM กับ Call Center, ทักษะการสื่อสารทางโทรศัพท์', 
 'Interactive Voice Response (IVR), VoIP Technology, Queue Management, CRM Integration, Tele-communication Skills'),

('954324', 'ไอทีสำหรับการท่องเที่ยว', 'IT for E-Tourism', 3, 3, 0, 6, 4, 
 'ระบบสำรองที่นั่ง (GDS), ตัวแทนท่องเที่ยวออนไลน์ (OTA), E-Booking, เทคโนโลยี AR/VR เพื่อการท่องเที่ยว, Smart Tourism', 
 'Global Distribution Systems (GDS), Online Travel Agencies (OTA), E-Booking, AR/VR for Tourism, Smart Tourism'),

('954326', 'ไอทีสำหรับอีเวนต์', 'IT in Event Management', 3, 3, 0, 6, 4, 
 'ระบบลงทะเบียนออนไลน์ (Registration Systems), เทคโนโลยี RFID/QR Code, การจัดอีเวนต์เสมือนจริง (Virtual Events), การจัดการผู้เข้าร่วมงาน', 
 'Online Registration Systems, RFID/QR Technologies, Virtual Events, Attendee Management'),

('954344', 'ความปลอดภัยเครือข่าย', 'Network Security', 3, 3, 0, 6, 4, 
 'ความมั่นคงปลอดภัยของระบบเครือข่าย การป้องกันการโจมตี การเข้ารหัส และไฟร์วอลล์', 
 'Network security, attack prevention, encryption, and firewalls.'),

('954347', 'พาณิชย์อิเล็กทรอนิกส์', 'E-Commerce', 3, 3, 0, 6, 4, 
 'รูปแบบธุรกิจพาณิชย์อิเล็กทรอนิกส์ การตลาดดิจิทัล ระบบชำระเงิน และกฎหมายที่เกี่ยวข้อง', 
 'E-Commerce business models, digital marketing, payment systems, and related laws.'),

('954371', 'การวางแผนการผลิต', 'Production Planning', 3, 3, 0, 6, 4, 
 'การวิเคราะห์และออกแบบระบบงานสำหรับการวางแผนและควบคุมการผลิต', 
 'Analysis and design of systems for production planning and control.'),

('954375', 'ระบบสินทรัพย์องค์กร', 'Enterprise Asset', 3, 3, 0, 6, 4, 
 'การวิเคราะห์และออกแบบระบบงานสำหรับบริหารจัดการสินทรัพย์องค์กรและงานบริการลูกค้า', 
 'Analysis and design of systems for enterprise asset management and customer service.'),

('954389', 'การฝึกงาน', 'Job Training', 3, 0, 18, 0, 4, 
 'การฝึกประสบการณ์วิชาชีพในหน่วยงานภาครัฐหรือเอกชน (ระยะสั้น)', 
 'Professional internship in public or private organizations (short-term).'),

('954410', 'ไอทีสำหรับลีน', 'IT for Lean', 3, 3, 0, 6, 4, 
 'การประยุกต์ใช้เทคโนโลยีสารสนเทศในการปรับปรุงกระบวนการแบบลีน (Lean Transformation)', 
 'Application of IT in Lean Transformation process improvement.'),

('954413', 'การตัดสินใจลงทุนไอที', 'IT Investment', 3, 3, 0, 6, 4, 
 'การวิเคราะห์ความคุ้มค่าและการตัดสินใจลงทุนในเทคโนโลยีสารสนเทศ', 
 'Cost-benefit analysis and decision making in IT investment.'),

('954417', 'ระบบบำรุงรักษา', 'Maintenance System', 3, 3, 0, 6, 4, 
 'การบำรุงรักษาเชิงป้องกัน (Preventive Maintenance), การคำนวณ OEE, ระบบ CMMS, การจัดการอะไหล่ (Spare Parts), IoT สำหรับการบำรุงรักษา', 
 'Preventive Maintenance, OEE Calculation, CMMS Systems, Spare Parts Management, IoT for Maintenance'),

('954421', 'อุปกรณ์เคลื่อนที่ธุรกิจ', 'Mobile Biz', 3, 3, 0, 6, 4, 
 'การใช้อุปกรณ์เคลื่อนที่และโมบายแอปพลิเคชันในการดำเนินธุรกิจ', 
 'Use of mobile devices and mobile applications in business operations.'),

('954422', 'CRM ท่องเที่ยว', 'CRM Tourism', 3, 3, 0, 6, 4, 
 'การจัดการความสัมพันธ์ลูกค้าและความสัมพันธ์ผู้จัดหาในธุรกิจท่องเที่ยวอิเล็กทรอนิกส์', 
 'Customer Relationship Management (CRM) and Supplier Relationship Management in E-Tourism.'),

('954423', 'นวัตกรรมบริการ', 'Service Innovation', 3, 3, 0, 6, 4, 
 'การสร้างสรรค์นวัตกรรมบริการเพื่อเพิ่มขีดความสามารถในการแข่งขัน', 
 'Creating service innovation to enhance competitiveness.'),

('954430', 'นิเวศธุรกิจดิจิทัล', 'Digital Ecosystem', 3, 3, 0, 6, 4, 
 'การวิเคราะห์และออกแบบระบบนิเวศทางธุรกิจดิจิทัลและแพลตฟอร์ม', 
 'Analysis and design of digital business ecosystems and platforms.'),

('954440', 'เว็บพอร์ทัล', 'Enterprise Portal', 3, 2, 2, 5, 4, 
 'การพัฒนาโปรแกรมประยุกต์แบบเว็บศูนย์รวมสำหรับองค์กร', 
 'Development of enterprise portal applications.'),

('954442', 'คลาวด์คอมพิวติ้ง', 'Cloud Computing', 3, 3, 0, 6, 4, 
 'หลักการประมวลผลแบบคลาวด์ สถาปัตยกรรม และการประยุกต์ใช้บริการคลาวด์ (IaaS, PaaS, SaaS)', 
 'Cloud computing principles, architecture, and application of cloud services (IaaS, PaaS, SaaS).'),

('954443', 'มัลติมีเดียธุรกิจ', 'Multimedia Biz', 3, 2, 2, 5, 4, 
 'การผลิตและประยุกต์ใช้สื่อมัลติมีเดีย กราฟิก และวิดีโอเพื่อธุรกิจดิจิทัล', 
 'Production and application of multimedia, graphics, and video for digital business.'),

('954444', 'โปรแกรม ERP', 'ERP Programming', 3, 2, 2, 5, 4, 
 'การเขียนโปรแกรมส่วนขยายและปรับแต่งระบบ ERP (เช่น ABAP)', 
 'Programming for ERP extensions and customization (e.g., ABAP).'),

('954445', 'สารสนเทศสุขภาพ', 'Healthcare IS', 3, 3, 0, 6, 4, 
 'ระบบสารสนเทศทางการแพทย์และสุขภาพ มาตรฐานข้อมูลสุขภาพ และการประยุกต์ใช้', 
 'Medical and healthcare information systems, health data standards, and applications.'),

('954447', 'สคริปต์ฝั่งลูกข่าย', 'Client-side Scripting', 3, 2, 2, 5, 4, 
 'การเขียนโปรแกรมสคริปต์บนฝั่งลูกข่ายเพื่อสร้างปฏิสัมพันธ์บนเว็บ (JavaScript Frameworks)', 
 'Client-side scripting for creating interactive web applications (JavaScript Frameworks).'),

('954448', 'เว็บเซอร์วิส', 'Web Service', 3, 2, 2, 5, 4, 
 'การพัฒนาและใช้งานเว็บเซอร์วิสสำหรับการบูรณาการระบบองค์กร (RESTful API, SOAP)', 
 'Development and usage of web services for enterprise system integration (RESTful API, SOAP).'),

('954449', 'พัฒนาแอปเร่งด่วน', 'RAD', 3, 2, 2, 5, 4, 
 'การพัฒนาโปรแกรมประยุกต์แบบรวดเร็ว (Rapid Application Development) และเครื่องมือ Low-code', 
 'Rapid Application Development (RAD) and Low-code tools.'),

('954466', 'จิตวิทยาออนไลน์', 'Online Psychology', 3, 3, 0, 6, 4, 
 'จิตวิทยาผู้บริโภคออนไลน์, การออกแบบ UX ตามหลักจิตวิทยา, แรงจูงใจในการซื้อ, Social Proof, ความไว้วางใจในโลกดิจิทัล', 
 'Online Consumer Behavior, UX Psychology, Purchase Motivation, Social Proof, Digital Trust'),

('954471', 'เหมืองข้อมูลธุรกิจ', 'Business Data Mining', 3, 2, 2, 5, 4, 
 'กระบวนการทำเหมืองข้อมูล การเตรียมข้อมูล การสร้างโมเดลพยากรณ์และการจำแนกข้อมูลทางธุรกิจ', 
 'Data mining process, data preparation, building prediction and classification models for business.'),

('954472', 'การแสดงภาพข้อมูล', 'Data Visualization', 3, 2, 2, 5, 4, 
 'หลักการแสดงภาพข้อมูล การใช้เครื่องมือสร้าง Dashboard เพื่อการตัดสินใจทางธุรกิจ', 
 'Data visualization principles, creating dashboards for business decision making.'),

('954473', 'กำหนดค่า ERP', 'ERP Configuration', 3, 2, 2, 5, 4, 
 'การกำหนดค่าระบบจัดการและวางแผนทรัพยากรองค์กรให้เหมาะสมกับกระบวนการธุรกิจ', 
 'Configuration of ERP systems to align with business processes.'),

('954474', 'รวบรวมข้อมูลดิจิทัล', 'Digital Data Gathering', 3, 2, 2, 5, 4, 
 'เทคนิคและเครื่องมือในการรวบรวมข้อมูลดิจิทัลจากแหล่งต่างๆ และการจัดการคุณภาพข้อมูล', 
 'Techniques and tools for gathering digital data from various sources and data quality management.'),

('954499', 'การค้นคว้าอิสระ', 'Independent Study', 3, 0, 6, 3, 4, 
 'การศึกษาค้นคว้าด้วยตนเองในหัวข้อที่น่าสนใจทางด้านการจัดการและเทคโนโลยีสารสนเทศ', 
 'Independent study on interesting topics in management and information technology.');
-- =========================================================
-- =========================================================
-- 5. INSERT STUDY PLAN (แผนการเรียน 4 ปี ครบ 8 เทอม)
-- =========================================================
-- ใช้ 'MMIT' เป็นรหัสหลักสูตร และใส่รหัสวิชาได้โดยตรง


INSERT INTO Study_Plan_Structures (curriculum_code, year_level, semester, course_code,name_en, name_th, remark_th, remark_en) VALUES
-- -----------------------------------------------------------------------------------------
-- ชั้นปีที่ 1 (Year 1)
-- -----------------------------------------------------------------------------------------
-- เทอม 1
('MMIT', 1, 1, '001101', 'วิชาศึกษาทั่วไป', 'General Education', 'ภาษาอังกฤษพื้นฐาน 1', 'Fundamental English 1'),
('MMIT', 1, 1, '140104', 'วิชาศึกษาทั่วไป', 'General Education', 'การเป็นพลเมือง', 'Citizenship'),
('MMIT', 1, 1, '206171', 'วิชาแกน', 'Core Course', 'คณิตศาสตร์ทั่วไป 1', 'General Mathematics 1'),
('MMIT', 1, 1, '954100', 'วิชาเอกบังคับ', 'Major Required', 'ระบบสารสนเทศองค์กร', 'IS for Organization'),
('MMIT', 1, 1, '954140', 'วิชาแกน', 'Core Course', 'พื้นฐานไอที', 'IT Literacy'),
('MMIT', 1, 1, '954142', 'วิชาแกน', 'Core Course', 'การเขียนโปรแกรมพื้นฐาน', 'Fund. Programming'),
('MMIT', 1, 1, NULL,     'วิชาศึกษาทั่วไป (เลือก)', 'General Education (Elective)', 'กลุ่มผู้เรียนรู้ (Learner Person)', 'Learner Person Group'),

-- เทอม 2
('MMIT', 1, 2, '001102', 'วิชาศึกษาทั่วไป', 'General Education', 'ภาษาอังกฤษพื้นฐาน 2', 'Fundamental English 2'),
('MMIT', 1, 2, '208263', 'วิชาแกน', 'Core Course', 'สถิติเบื้องต้น', 'Elementary Statistics'),
('MMIT', 1, 2, '954143', 'วิชาแกน', 'Core Course', 'การจัดการข้อมูล', 'Data Management'),
('MMIT', 1, 2, '954170', 'วิชาแกน', 'Core Course', 'แบบจำลองธุรกิจ', 'Business Process Modeling'),
('MMIT', 1, 2, '954246', 'วิชาเอกบังคับ', 'Major Required', 'การเขียนโปรแกรมขั้นสูง', 'Adv. Programming'),
('MMIT', 1, 2, '954248', 'วิชาแกน', 'Core Course', 'เทคโนโลยีสารสนเทศและการสื่อสาร', 'ICT'),
('MMIT', 1, 2, '204100', 'วิชาศึกษาทั่วไป', 'General Education', 'ไอทีและชีวิตสมัยใหม่', 'IT and Modern Life'),

-- -----------------------------------------------------------------------------------------
-- ชั้นปีที่ 2 (Year 2)
-- -----------------------------------------------------------------------------------------
-- เทอม 1
('MMIT', 2, 1, '001201', 'วิชาศึกษาทั่วไป', 'General Education', 'การอ่านเชิงวิเคราะห์และการเขียน', 'Critical Reading'),
('MMIT', 2, 1, '208262', 'วิชาแกน', 'Core Course', 'สถิติสำหรับไอที', 'Stat for IT'),
('MMIT', 2, 1, '954230', 'วิชาแกน', 'Core Course', 'การติดตามทางการเงิน', 'Financial Tracking'),
('MMIT', 2, 1, '954231', 'วิชาแกน', 'Core Course', 'การจัดการทุนมนุษย์', 'Human Capital Management'),
('MMIT', 2, 1, '954244', 'วิชาเอกบังคับ', 'Major Required', 'วิเคราะห์และออกแบบระบบ', 'System Analysis and Design'),
('MMIT', 2, 1, '954340', 'วิชาเอกบังคับ', 'Major Required', 'ออกแบบฐานข้อมูลองค์กร', 'Enterprise DB Design'),
('MMIT', 2, 1, NULL,     'วิชาศึกษาทั่วไป (เลือก)', 'General Education (Elective)', 'กลุ่มผู้ร่วมสร้างสรรค์นวัตกรรม', 'Innovative Co-creator Group'),

-- เทอม 2
('MMIT', 2, 2, '001229', 'วิชาศึกษาทั่วไป', 'General Education', 'ภาษาอังกฤษสำหรับศิลปะสื่อ', 'English for Media Arts'),
('MMIT', 2, 2, '954370', 'วิชาเอกบังคับ', 'Major Required', 'การจัดการวัสดุ', 'Material Management'),
('MMIT', 2, 2, '954374', 'วิชาเอกบังคับ', 'Major Required', 'การขายและการจัดจำหน่าย', 'Sales & Distribution'),
('MMIT', 2, 2, '954416', 'วิชาเอกบังคับ', 'Major Required', 'โซ่อุปทานและลูกค้าสัมพันธ์', 'Supply Chain & CRM'),
('MMIT', 2, 2, NULL,     'วิชาศึกษาทั่วไป (เลือก)', 'General Education (Elective)', 'กลุ่มพลเมืองที่เข้มแข็ง', 'Active Citizen Group'),
('MMIT', 2, 2, NULL,     'วิชาเลือกเสรี', 'Free Elective', 'วิชาเลือกเสรี 1', 'Free Elective 1'),

-- -----------------------------------------------------------------------------------------
-- ชั้นปีที่ 3 (Year 3)
-- -----------------------------------------------------------------------------------------
-- เทอม 1
('MMIT', 3, 1, '954310', 'วิชาเอกบังคับ', 'Major Required', 'ระบบ ERP', 'Enterprise Resource Planning'),
('MMIT', 3, 1, '954365', 'วิชาเอกบังคับ', 'Major Required', 'การจัดการความรู้', 'Knowledge Management'),
('MMIT', 3, 1, '954381', 'วิชาเอกบังคับ', 'Major Required', 'เตรียมความพร้อมฝึกงาน', 'Prep for WIL'),
('MMIT', 3, 1, NULL,     'วิชาเอกเลือก', 'Major Elective', 'วิชาเอกเลือก 1', 'Major Elective 1'),
('MMIT', 3, 1, NULL,     'วิชาเอกเลือก', 'Major Elective', 'วิชาเอกเลือก 2', 'Major Elective 2'),
('MMIT', 3, 1, NULL,     'วิชาเอกเลือก', 'Major Elective', 'วิชาเอกเลือก 3', 'Major Elective 3'),

-- เทอม 2
('MMIT', 3, 2, '954346', 'วิชาเอกบังคับ', 'Major Required', 'การพัฒนาแอปธุรกิจ', 'Business App Dev'),
('MMIT', 3, 2, '954490', 'วิชาเอกบังคับ', 'Major Required', 'ระเบียบวิธีวิจัยไอที', 'Research Methodology'),
('MMIT', 3, 2, NULL,     'วิชาเอกเลือก', 'Major Elective', 'วิชาเอกเลือก 4', 'Major Elective 4'),
('MMIT', 3, 2, NULL,     'วิชาเอกเลือก', 'Major Elective', 'วิชาเอกเลือก 5', 'Major Elective 5'),
('MMIT', 3, 2, NULL,     'วิชาเอกเลือก', 'Major Elective', 'วิชาเอกเลือก 6', 'Major Elective 6'),
('MMIT', 3, 2, NULL,     'วิชาศึกษาทั่วไป (เลือก)', 'General Education (Elective)', 'วิชา GE ตัวสุดท้าย', 'Last GE Elective'),

-- -----------------------------------------------------------------------------------------
-- ชั้นปีที่ 4 (Year 4)
-- -----------------------------------------------------------------------------------------
-- เทอม 1
('MMIT', 4, 1, '954484', 'วิชาเอกบังคับ', 'Major Required', 'สหกิจศึกษา 1', 'Work Integrated Learning 1'),

-- เทอม 2
('MMIT', 4, 2, '954485', 'วิชาเอกบังคับ', 'Major Required', 'สหกิจศึกษา 2', 'Work Integrated Learning 2');

INSERT INTO Career_Paths (id, curriculum_code, name_th, name_en, description) VALUES 
(1, 'MMIT', 'นักวิเคราะห์ธุรกิจดิจิตอล', 'Digital Business analyst', 'ผแปลความต้องการของธุรกิจให้กลายเป็นระบบดิจิทัลที่ใช้งานได้จริง ขับเคลื่อนการตัดสินใจด้วยข้อมูล เน้น process + data + digital solution'),
(2, 'MMIT', 'นักพัฒนาโปรแกรมประยุต์เว็บไซต์', 'Web application Developer', 'ผู้เชี่ยวชาญด้านการเขียนโปรแกรมและการพัฒนาแเว็บไซต์ (Full-stack Web  Deveroper)'),
(3, 'MMIT', 'นักปฏิบัติงานสายสนับสนุนเทคโนโลยีสารสนเทศ', 'IT Support Sprcialist', 'คือผู้เชี่ยวชาญด้านการสนับสนุนระบบไอที รับผิดชอบแก้ไขปัญหาฮาร์ดแวร์ ซอฟต์แวร์ และเครือข่าย เพื่อให้ผู้ใช้งานและระบบทำงานได้อย่างต่อเนื่อง มีประสิทธิภาพ และปลอดภัย)'),
(4, 'MMIT', 'ผู้ดูแลฐานระบบธุรกิจ', 'Business database administrator', 'ผูคือผู้ดูแลและบริหารฐานข้อมูลเพื่อรองรับการทำงานของธุรกิจ ดูแลความถูกต้อง ความปลอดภัย และประสิทธิภาพของข้อมูล เพื่อให้ข้อมูลพร้อมใช้งานในการดำเนินงานและการตัดสินใจทางธุรกิจ)'),
(5, 'MMIT', 'ผู้ช่วยการวางแผนและจัดสรรทรัพยากรองค์กร', 'ERP Assistant', 'ผู้ช่วยการวางแผนและจัดสรรทรัพยากรองค์กร (SAP/ERP)'),
(6, 'MMIT', 'ผู้ประสานงานขายฝั่งเทคโนโลยี', 'IT & Sales solution coordinator', 'ผคือผู้ประสานงานระหว่างทีมขายและทีมไอที แปลงความต้องการของลูกค้าเป็นโซลูชันด้านเทคโนโลยีที่เหมาะสม เพื่อสนับสนุนการขาย การใช้งานระบบ และความสำเร็จของลูกค้า');
-- =========================================================
-- 6. INSERT CAREER PATHS
-- =========================================================
-- =========================================================
-- CLEANUP & PREPARATION
-- =========================================================
-- ลบข้อมูล Roadmap เก่าถ้ามี (เพื่อป้องกัน Duplicate)
DELETE FROM Career_Roadmaps WHERE career_id BETWEEN 1 AND 6;

-- =========================================================
-- INSERT CAREER ROADMAPS (Based on MMIT Curriculum Images)
-- =========================================================

-- ---------------------------------------------------------
-- 1. Digital Business Analyst (นักวิเคราะห์ธุรกิจดิจิทัล)
-- Focus: Process Analysis, Requirement Gathering, Business Logic, Data usage
-- ---------------------------------------------------------
-- =========================================================
-- CLEANUP: ลบข้อมูลเก่าเพื่อป้องกันการซ้ำซ้อน
-- =========================================================
-- =========================================================
-- STEP 1: ล้างค่าเก่าและปิดการตรวจสอบชั่วคราว (เพื่อความลื่นไหล)
-- =========================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Career_Skills; -- ล้างข้อมูลเก่าออกก่อน
SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- STEP 2: สร้าง SKILL ใหม่ (ตามชื่อที่คุณระบุเป๊ะๆ)
-- =========================================================

-- 1. Digital Business Analyst
INSERT IGNORE INTO Skills (name_th, name_en, description) VALUES 
('การวิเคราะห์ข้อมูล', 'Data Analysis', 'Analyzing raw data'),
('ธุรกิจอัจฉริยะ', 'Business Intelligence', 'BI tools and strategies'),
('การสร้างรายงาน', 'Report Creation', 'Generating business reports'),
('การปรับปรุงกระบวนการ', 'Process Optimization', 'Improving business workflows');

-- 2. Web Application Developer
INSERT IGNORE INTO Skills (name_th, name_en, description) VALUES 
('HTML/CSS/JS', 'HTML/CSS/JavaScript', 'Core web technologies'),
('Frontend Frameworks', 'React/Vue/Angular', 'Modern frontend libraries'),
('Backend Runtime', 'Node.js', 'JavaScript runtime'),
('การจัดการฐานข้อมูล', 'Database Management', 'Managing databases'),
('การพัฒนา API', 'API Development', 'Building RESTful/GraphQL APIs');

-- 3. IT Support Specialist
INSERT IGNORE INTO Skills (name_th, name_en, description) VALUES 
('การสนับสนุนทางเทคนิค', 'Technical Support', 'Assisting users with technical issues'),
('การดูแลเครือข่าย', 'Network Administration', 'Managing computer networks'),
('การบำรุงรักษาระบบ', 'System Maintenance', 'Keeping systems running smoothly'),
('การแก้ปัญหา', 'Troubleshooting', 'Diagnosing and fixing faults');

-- 4. Business Database Administrator
INSERT IGNORE INTO Skills (name_th, name_en, description) VALUES 
('SQL/NoSQL', 'SQL/NoSQL', 'Relational and Non-relational DBs'),
('การออกแบบฐานข้อมูล', 'Database Design', 'Designing database schema'),
('การปรับแต่งประสิทธิภาพ', 'Performance Tuning', 'Optimizing database speed'),
('ความปลอดภัยข้อมูล', 'Data Security', 'Protecting database data'),
('การสำรองและกู้คืน', 'Backup & Recovery', 'Disaster recovery planning');

-- 5. ERP Assistant
INSERT IGNORE INTO Skills (name_th, name_en, description) VALUES 
('ระบบ ERP', 'SAP/Oracle ERP', 'Enterprise Resource Planning software'),
('กระบวนการทางธุรกิจ', 'Business Process', 'Understanding workflow logic'),
('การตั้งค่าโมดูล', 'Module Configuration', 'Configuring ERP modules'),
('การอบรมผู้ใช้', 'User Training', 'Teaching users how to use the system');

-- 6. IT Sales & Solution Coordinator
INSERT IGNORE INTO Skills (name_th, name_en, description) VALUES 
('การขายโซลูชัน', 'Solution Selling', 'Selling complex solutions'),
('การนำเสนอทางเทคนิค', 'Technical Presentation', 'Presenting tech products'),
('ลูกค้าสัมพันธ์', 'Client Relations', 'Managing customer relationships'),
('ความรู้ในผลิตภัณฑ์', 'Product Knowledge', 'Understanding what you sell');


-- =========================================================
-- STEP 3: จับคู่ CAREER กับ SKILL (INSERT ข้อมูลจริง)
-- =========================================================

-- 1. Digital Business Analyst
INSERT INTO Career_Skills (career_id, skill_id, importance) VALUES
(1, (SELECT id FROM Skills WHERE name_en = 'Data Analysis'), 'Essential'),
(1, (SELECT id FROM Skills WHERE name_en = 'Business Intelligence'), 'Essential'),
(1, (SELECT id FROM Skills WHERE name_en = 'Report Creation'), 'Recommended'),
(1, (SELECT id FROM Skills WHERE name_en = 'Process Optimization'), 'Recommended');

-- 2. Web Application Developer
INSERT INTO Career_Skills (career_id, skill_id, importance) VALUES
(2, (SELECT id FROM Skills WHERE name_en = 'HTML/CSS/JavaScript'), 'Essential'),
(2, (SELECT id FROM Skills WHERE name_en = 'React/Vue/Angular'), 'Essential'),
(2, (SELECT id FROM Skills WHERE name_en = 'Node.js'), 'Essential'),
(2, (SELECT id FROM Skills WHERE name_en = 'Database Management'), 'Recommended'),
(2, (SELECT id FROM Skills WHERE name_en = 'API Development'), 'Recommended');

-- 3. IT Support Specialist
INSERT INTO Career_Skills (career_id, skill_id, importance) VALUES
(3, (SELECT id FROM Skills WHERE name_en = 'Technical Support'), 'Essential'),
(3, (SELECT id FROM Skills WHERE name_en = 'Network Administration'), 'Essential'),
(3, (SELECT id FROM Skills WHERE name_en = 'System Maintenance'), 'Recommended'),
(3, (SELECT id FROM Skills WHERE name_en = 'Troubleshooting'), 'Essential');

-- 4. Business Database Administrator
INSERT INTO Career_Skills (career_id, skill_id, importance) VALUES
(4, (SELECT id FROM Skills WHERE name_en = 'SQL/NoSQL'), 'Essential'),
(4, (SELECT id FROM Skills WHERE name_en = 'Database Design'), 'Essential'),
(4, (SELECT id FROM Skills WHERE name_en = 'Performance Tuning'), 'Essential'),
(4, (SELECT id FROM Skills WHERE name_en = 'Data Security'), 'Essential'),
(4, (SELECT id FROM Skills WHERE name_en = 'Backup & Recovery'), 'Recommended');

-- 5. ERP Assistant
INSERT INTO Career_Skills (career_id, skill_id, importance) VALUES
(5, (SELECT id FROM Skills WHERE name_en = 'SAP/Oracle ERP'), 'Essential'),
(5, (SELECT id FROM Skills WHERE name_en = 'Business Process'), 'Essential'),
(5, (SELECT id FROM Skills WHERE name_en = 'Module Configuration'), 'Recommended'),
(5, (SELECT id FROM Skills WHERE name_en = 'User Training'), 'Recommended');

-- 6. IT Sales & Solution Coordinator
INSERT INTO Career_Skills (career_id, skill_id, importance) VALUES
(6, (SELECT id FROM Skills WHERE name_en = 'Solution Selling'), 'Essential'),
(6, (SELECT id FROM Skills WHERE name_en = 'Technical Presentation'), 'Essential'),
(6, (SELECT id FROM Skills WHERE name_en = 'Client Relations'), 'Recommended'),
(6, (SELECT id FROM Skills WHERE name_en = 'Product Knowledge'), 'Essential');


-- =========================================================
-- STEP 4: STUDENT WORKLOAD ANALYSIS (ที่คุณพยายามรันตอนท้าย)
-- =========================================================
SELECT 
    code, 
    name_en, 
    (lecture_hours + lab_hours + self_study_hours) AS Total_Weekly_Hours, 
    CASE 
        WHEN (lecture_hours + lab_hours + self_study_hours) >= 12 THEN 'Heavy Load (Critical)' 
        WHEN (lecture_hours + lab_hours + self_study_hours) >= 9 THEN 'Moderate Load' 
        ELSE 'Light Load' 
    END AS Workload_Category 
FROM Courses_MMIT_65 
ORDER BY Total_Weekly_Hours DESC 
LIMIT 5;
SELECT 
    cr.id AS Roadmap_ID,
    cp.name_th AS Career_Name,          -- ชื่ออาชีพ (ไทย)
    cp.name_en AS Career_Name_EN,       -- ชื่ออาชีพ (อังกฤษ)
    c.code AS Course_Code,
    c.name_th AS Course_Name,           -- ชื่อวิชา
    s.name_th AS Skill_Name,            -- ชื่อสกิล (ไทย)
    s.name_en AS Skill_Name_EN,         -- ชื่อสกิล (อังกฤษ)
    cr.importance AS Level              -- ความสำคัญ
FROM Career_Roadmaps cr
JOIN Career_Paths cp ON cr.career_id = cp.id
JOIN Courses_MMIT_65 c ON cr.course_code = c.code
JOIN Skills s ON cr.skill_id = s.id;
-- =========================================================
-- 8. INSERT PREREQUISITES (แก้ไข Error 1146 โดยใช้ Code)
-- =========================================================
-- 1. สายภาษา (Language)
INSERT INTO Prerequisites_MMIT_65 (course_code, prereq_course_code) VALUES
('001102', '001101'), -- Eng 2 ต้องผ่าน Eng 1 ก่อน
('001201', '001102'); -- Critical Reading ต้องผ่าน Eng 2 ก่อน

-- 2. สายเขียนโปรแกรม (Programming Path) - **สำคัญมาก**
INSERT INTO Prerequisites_MMIT_65 (course_code, prereq_course_code) VALUES
('954246', '954142'), -- Advanced Programming (OOP) ต้องผ่าน Fund. Programming ก่อน
('954240', '954142'), -- Web Programming ต้องผ่าน Fund. Programming ก่อน
('954346', '954143'), -- ต้องผ่าน Data Management
('954346', '954170'), -- ต้องผ่าน BPMN-- Business App Dev ต้องผ่าน Advanced Programming ก่อน
('954447', '954240'), -- Client-side Scripting ต้องผ่าน Web Programming ก่อน
('954448', '954240'); -- Web Service ต้องผ่าน Web Programming ก่อน

-- 3. สายข้อมูล (Data Path)
INSERT INTO Prerequisites_MMIT_65 (course_code, prereq_course_code) VALUES
('954340', '954143'), -- Enterprise DB Design ต้องผ่าน Data Management ก่อน
('954471', '954340'), -- Data Mining ต้องผ่าน Enterprise DB Design ก่อน
('954472', '954340'); -- Data Visualization ควรมีความรู้ Enterprise DB ก่อน

-- 4. สายบริหารจัดการและ ERP (Management & ERP Path)
INSERT INTO Prerequisites_MMIT_65 (course_code, prereq_course_code) VALUES
('954416', '954100'), -- Supply Chain & CRM ต้องผ่าน IS for Organization ก่อน
('954473', '954310'), -- ERP Configuration ต้องผ่าน ERP Systems ก่อน
('954444', '954310'), -- ERP Programming ต้องผ่าน ERP Systems ก่อน
('954371', '954170'); -- Production Planning ควรผ่าน Business Process Modeling ก่อน

-- 5. สายโครงสร้างพื้นฐาน (Infrastructure & Network)
INSERT INTO Prerequisites_MMIT_65 (course_code, prereq_course_code) VALUES
('954344', '954248'), -- Network Security ต้องผ่าน ICT (Network Basics) ก่อน
('954442', '954248'); -- Cloud Computing ต้องผ่าน ICT ก่อน

-- 6. สายสหกิจศึกษา (Work Integrated Learning)
INSERT INTO Prerequisites_MMIT_65 (course_code, prereq_course_code) VALUES
('954484', '954381'), -- สหกิจ 1 (WIL 1) ต้องผ่าน Prep for WIL ก่อน
('954485', '954484'); -- สหกิจ 2 (WIL 2) ต้องผ่าน WIL 1 ก่อน

-- 1. Student Workload Analysis (วิเคราะห์ภาระงานนักศึกษา)
-- Insight: หาวิชาที่ "โหด" ที่สุด (ใช้เวลาเรียน + ทำงานเองเยอะสุด) เพื่อแจ้งเตือนนักศึกษา
-- Skill Showcased: Calculated Fields & Sorting
SELECT 
    code,
    name_en,
    (lecture_hours + lab_hours + self_study_hours) AS Total_Weekly_Hours,
    CASE 
        WHEN (lecture_hours + lab_hours + self_study_hours) >= 12 THEN 'Heavy Load (Critical)'
        WHEN (lecture_hours + lab_hours + self_study_hours) >= 9 THEN 'Moderate Load'
        ELSE 'Light Load'
    END AS Workload_Category
FROM Courses_MMIT_65
ORDER BY Total_Weekly_Hours DESC
LIMIT 5;

-- 2. Resource Planning: Lab Intensity by Course Type (การบริหารทรัพยากรห้องแล็บ)
-- Insight: หมวดวิชาไหนใช้ห้องปฏิบัติการคอมพิวเตอร์เยอะที่สุด? (เพื่อวางแผนงบประมาณ/การจองห้อง)
-- Skill Showcased: JOIN, GROUP BY, Aggregation with Ratio
SELECT 
    t.name_en AS Course_Type,
    COUNT(c.id) AS Course_Count,
    SUM(c.lab_hours) AS Total_Lab_Hours_Required,
    -- คำนวณสัดส่วน: ชั่วโมงแล็บเทียบกับชั่วโมงเรียนทั้งหมดในหมวดนั้น คิดเป็นกี่ %
    ROUND(SUM(c.lab_hours) * 100.0 / NULLIF(SUM(c.lecture_hours + c.lab_hours), 0), 2) AS Practical_Intensity_Percent
FROM Courses_MMIT_65 c
JOIN CourseTypes t ON c.type_id = t.id
GROUP BY t.name_en
ORDER BY Total_Lab_Hours_Required DESC;

-- 3. Critical Path Identification (วิเคราะห์วิชาที่เป็นคอขวด)
-- Insight: วิชานี้ห้ามเปิดน้อย/ห้ามชน เพราะเป็นตัวต่อ (Prerequisite) ของวิชาอื่นจำนวนมาก
-- Skill Showcased: JOIN with Sub-query logic (Count dependencies)
SELECT 
    p.prereq_course_code AS Bottleneck_Course_Code,
    c.name_en AS Course_Name,
    COUNT(p.course_code) AS Unlocks_Next_Courses_Count
FROM Prerequisites_MMIT_65 p
JOIN Courses_MMIT_65 c ON p.prereq_course_code = c.code
GROUP BY p.prereq_course_code, c.name_en
HAVING COUNT(p.course_code) > 1 -- เอาเฉพาะวิชาที่ปลดล็อกได้มากกว่า 1 ตัว
ORDER BY Unlocks_Next_Courses_Count DESC;

-- 4. "Total Degree Footprint" (สรุปภาพรวมตลอดหลักสูตร)
-- Insight: ถ้าเก็บครบทุกวิชาในหลักสูตร (สมมติ) ต้องใช้เวลาชีวิตเท่าไหร่?
-- Business Value: Resource Planning สำหรับมหาวิทยาลัย (ต้องเตรียมห้องเรียนกี่ชั่วโมง)
SELECT 
    COUNT(*) AS Total_Courses_Offered,
    SUM(lecture_hours) AS Total_Lecture_Hall_Hours_Needed,
    SUM(lab_hours) AS Total_Computer_Lab_Hours_Needed,
    SUM(self_study_hours) AS Total_Student_Homework_Hours
FROM Courses_MMIT_65;

-- 5. Curriculum Content Gap Analysis (วิเคราะห์ Keyword ในคำอธิบายรายวิชา)
-- Insight: หลักสูตรเราเน้น "Data" หรือ "Management" มากกว่ากัน? (Text Mining เบื้องต้นด้วย SQL)
-- Skill Showcased: Conditional Aggregation (Pivot-like logic)
SELECT 
    'Curriculum Focus' AS Metric,
    SUM(CASE WHEN description_en LIKE '%Data%' OR name_en LIKE '%Data%' THEN 1 ELSE 0 END) AS Data_Related_Courses,
    SUM(CASE WHEN description_en LIKE '%Management%' OR name_en LIKE '%Management%' THEN 1 ELSE 0 END) AS Management_Related_Courses,
    SUM(CASE WHEN description_en LIKE '%Programming%' OR name_en LIKE '%Programming%' THEN 1 ELSE 0 END) AS Coding_Related_Courses
FROM Courses_MMIT_65;

