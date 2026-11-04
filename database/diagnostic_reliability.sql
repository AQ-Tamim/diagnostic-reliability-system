-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 04, 2026 at 11:59 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `diagnostic_reliability`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_complete_test_order` (IN `p_order_id` INT, IN `p_equipment_id` INT, IN `p_batch_id` INT, IN `p_result_value` DECIMAL(10,3), IN `p_interpretation` VARCHAR(30))   BEGIN
    DECLARE v_order_status VARCHAR(30) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    
    SELECT order_status
    INTO v_order_status
    FROM TEST_ORDER
    WHERE order_id = p_order_id
    FOR UPDATE;

    
    IF v_order_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Test order does not exist';
    END IF;

    
    IF v_order_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only pending orders can be completed';
    END IF;

    
    INSERT INTO TEST_RESULT (
        order_id,
        equipment_id,
        batch_id,
        performed_at,
        result_value,
        interpretation
    )
    VALUES (
        p_order_id,
        p_equipment_id,
        p_batch_id,
        NOW(),
        p_result_value,
        p_interpretation
    );

    
    UPDATE TEST_ORDER
    SET order_status = 'Completed'
    WHERE order_id = p_order_id;

    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bayesian_assessment`
--

CREATE TABLE `bayesian_assessment` (
  `assessment_id` int(11) NOT NULL,
  `result_id` int(11) NOT NULL,
  `performance_id` int(11) NOT NULL,
  `prevalence_id` int(11) NOT NULL,
  `model_version_id` int(11) NOT NULL,
  `posterior_probability` decimal(8,7) NOT NULL,
  `assessed_at` datetime DEFAULT current_timestamp()
) ;

--
-- Dumping data for table `bayesian_assessment`
--

INSERT INTO `bayesian_assessment` (`assessment_id`, `result_id`, `performance_id`, `prevalence_id`, `model_version_id`, `posterior_probability`, `assessed_at`) VALUES
(1, 1, 1, 1, 1, 0.4922280, '2026-11-04 11:38:41'),
(2, 2, 1, 1, 1, 0.0010401, '2026-11-04 11:38:41'),
(3, 3, 1, 1, 1, 0.4922280, '2026-11-04 11:38:41'),
(4, 4, 1, 1, 1, 0.0010401, '2026-11-04 11:38:41'),
(5, 5, 1, 1, 1, 0.4922280, '2026-11-04 11:38:41'),
(6, 6, 1, 1, 1, 0.4922280, '2026-11-04 11:38:41'),
(7, 7, 1, 1, 1, 0.4922280, '2026-11-04 11:38:41');

-- --------------------------------------------------------

--
-- Table structure for table `calibration`
--

CREATE TABLE `calibration` (
  `calibration_id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `calibration_date` datetime NOT NULL,
  `valid_until` datetime DEFAULT NULL,
  `calibration_outcome` varchar(30) NOT NULL,
  `technician_name` varchar(100) DEFAULT NULL
) ;

--
-- Dumping data for table `calibration`
--

INSERT INTO `calibration` (`calibration_id`, `equipment_id`, `calibration_date`, `valid_until`, `calibration_outcome`, `technician_name`) VALUES
(1, 1, '2026-03-01 08:00:00', '2026-09-01 08:00:00', 'Passed', 'Technician A'),
(2, 2, '2026-03-15 08:00:00', '2026-09-15 08:00:00', 'Passed', 'Technician B'),
(3, 3, '2026-02-01 08:00:00', '2026-08-01 08:00:00', 'Failed', 'Technician C');

-- --------------------------------------------------------

--
-- Table structure for table `diagnostic_test`
--

CREATE TABLE `diagnostic_test` (
  `test_id` int(11) NOT NULL,
  `test_name` varchar(100) NOT NULL,
  `test_category` varchar(50) DEFAULT NULL,
  `measurement_unit` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `diagnostic_test`
--

INSERT INTO `diagnostic_test` (`test_id`, `test_name`, `test_category`, `measurement_unit`) VALUES
(1, 'Disease X Screening Test', 'Antigen Detection', 'Qualitative');

-- --------------------------------------------------------

--
-- Table structure for table `disease`
--

CREATE TABLE `disease` (
  `disease_id` int(11) NOT NULL,
  `disease_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `disease`
--

INSERT INTO `disease` (`disease_id`, `disease_name`, `description`) VALUES
(1, 'Disease X', 'Synthetic disease category used for Bayesian diagnostic simulation.');

-- --------------------------------------------------------

--
-- Table structure for table `disease_prevalence`
--

CREATE TABLE `disease_prevalence` (
  `prevalence_id` int(11) NOT NULL,
  `disease_id` int(11) NOT NULL,
  `population_label` varchar(150) NOT NULL,
  `prevalence` decimal(6,5) NOT NULL,
  `source_reference` varchar(500) NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL
) ;

--
-- Dumping data for table `disease_prevalence`
--

INSERT INTO `disease_prevalence` (`prevalence_id`, `disease_id`, `population_label`, `prevalence`, `source_reference`, `effective_from`, `effective_to`) VALUES
(1, 1, 'Synthetic Target Population', 0.02000, 'Illustrative simulation assumption; not a clinical estimate.', '2026-01-01', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `equipment`
--

CREATE TABLE `equipment` (
  `equipment_id` int(11) NOT NULL,
  `lab_id` int(11) NOT NULL,
  `manufacturer` varchar(100) NOT NULL,
  `model_number` varchar(100) DEFAULT NULL,
  `serial_number` varchar(100) NOT NULL,
  `installation_date` date DEFAULT NULL,
  `operational_status` varchar(30) DEFAULT NULL
) ;

--
-- Dumping data for table `equipment`
--

INSERT INTO `equipment` (`equipment_id`, `lab_id`, `manufacturer`, `model_number`, `serial_number`, `installation_date`, `operational_status`) VALUES
(1, 1, 'MedTech', 'MT-200', 'MT001', '2023-01-15', 'Operational'),
(2, 1, 'MedTech', 'MT-200', 'MT002', '2023-06-20', 'Operational'),
(3, 2, 'BioLab', 'BL-500', 'BL001', '2022-11-10', 'Under Maintenance');

-- --------------------------------------------------------

--
-- Table structure for table `equipment_reliability_assessment`
--

CREATE TABLE `equipment_reliability_assessment` (
  `reliability_assessment_id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `model_version_id` int(11) NOT NULL,
  `observation_start` date NOT NULL,
  `observation_end` date NOT NULL,
  `prior_alpha` decimal(10,5) NOT NULL,
  `prior_beta` decimal(10,5) NOT NULL,
  `qc_observations` int(11) NOT NULL,
  `qc_failures` int(11) NOT NULL,
  `posterior_alpha` decimal(10,5) NOT NULL,
  `posterior_beta` decimal(10,5) NOT NULL,
  `posterior_mean_failure_probability` decimal(10,7) NOT NULL,
  `assessed_at` datetime DEFAULT current_timestamp(),
  `failure_probability_ci_lower` decimal(10,7) NOT NULL,
  `failure_probability_ci_upper` decimal(10,7) NOT NULL
) ;

--
-- Dumping data for table `equipment_reliability_assessment`
--

INSERT INTO `equipment_reliability_assessment` (`reliability_assessment_id`, `equipment_id`, `model_version_id`, `observation_start`, `observation_end`, `prior_alpha`, `prior_beta`, `qc_observations`, `qc_failures`, `posterior_alpha`, `posterior_beta`, `posterior_mean_failure_probability`, `assessed_at`, `failure_probability_ci_lower`, `failure_probability_ci_upper`) VALUES
(1, 1, 2, '2026-04-01', '2026-04-05', 1.00000, 1.00000, 2, 0, 1.00000, 3.00000, 0.2500000, '2026-11-03 16:51:59', 0.0084038, 0.7075982),
(2, 2, 2, '2026-04-02', '2026-04-06', 1.00000, 1.00000, 2, 1, 2.00000, 2.00000, 0.5000000, '2026-11-03 16:51:59', 0.0942993, 0.9057007),
(3, 3, 2, '2026-04-06', '2026-04-06', 1.00000, 1.00000, 1, 1, 2.00000, 1.00000, 0.6666667, '2026-11-03 16:51:59', 0.1581139, 0.9874209);

-- --------------------------------------------------------

--
-- Table structure for table `laboratory`
--

CREATE TABLE `laboratory` (
  `lab_id` int(11) NOT NULL,
  `lab_name` varchar(100) NOT NULL,
  `location` varchar(150) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `laboratory`
--

INSERT INTO `laboratory` (`lab_id`, `lab_name`, `location`) VALUES
(1, 'Central Diagnostic Laboratory', 'Dhaka'),
(2, 'Northside Diagnostic Laboratory', 'Dhaka');

-- --------------------------------------------------------

--
-- Table structure for table `maintenance`
--

CREATE TABLE `maintenance` (
  `maintenance_id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `maintenance_date` datetime NOT NULL,
  `maintenance_type` varchar(50) DEFAULT NULL,
  `maintenance_notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `maintenance`
--

INSERT INTO `maintenance` (`maintenance_id`, `equipment_id`, `maintenance_date`, `maintenance_type`, `maintenance_notes`) VALUES
(1, 1, '2026-02-15 10:00:00', 'Routine', 'Routine preventive maintenance.'),
(2, 2, '2026-03-20 11:00:00', 'Inspection', 'Minor performance irregularity observed.'),
(3, 3, '2026-04-04 09:00:00', 'Repair', 'Machine requires component replacement.');

-- --------------------------------------------------------

--
-- Table structure for table `model_version`
--

CREATE TABLE `model_version` (
  `model_version_id` int(11) NOT NULL,
  `model_name` varchar(100) NOT NULL,
  `version_number` varchar(30) NOT NULL,
  `model_description` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `model_version`
--

INSERT INTO `model_version` (`model_version_id`, `model_name`, `version_number`, `model_description`, `created_at`) VALUES
(1, 'Bayesian Diagnostic Assessment', '1.0', 'Baseline Bayesian model using disease prevalence, diagnostic sensitivity, and specificity.', '2026-11-02 17:20:07'),
(2, 'Beta-Binomial Equipment Reliability', '1.0', 'Estimates equipment QC failure probability using historical quality-control observations.', '2026-11-02 18:21:14');

-- --------------------------------------------------------

--
-- Table structure for table `patient`
--

CREATE TABLE `patient` (
  `patient_id` int(11) NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `sex` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `patient`
--

INSERT INTO `patient` (`patient_id`, `date_of_birth`, `sex`) VALUES
(1, '2001-04-12', 'Male'),
(2, '1998-09-23', 'Female'),
(3, '2003-01-15', 'Male'),
(4, '1995-06-08', 'Female'),
(5, '2000-11-30', 'Male');

-- --------------------------------------------------------

--
-- Table structure for table `quality_control`
--

CREATE TABLE `quality_control` (
  `qc_id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `observation_date` datetime NOT NULL,
  `expected_value` decimal(10,3) DEFAULT NULL,
  `observed_value` decimal(10,3) DEFAULT NULL,
  `qc_status` varchar(30) NOT NULL
) ;

--
-- Dumping data for table `quality_control`
--

INSERT INTO `quality_control` (`qc_id`, `equipment_id`, `observation_date`, `expected_value`, `observed_value`, `qc_status`) VALUES
(1, 1, '2026-04-01 08:00:00', 100.000, 99.500, 'Passed'),
(2, 1, '2026-04-05 08:00:00', 100.000, 100.200, 'Passed'),
(3, 2, '2026-04-02 08:00:00', 100.000, 96.000, 'Failed'),
(4, 2, '2026-04-06 08:00:00', 100.000, 98.000, 'Passed'),
(5, 3, '2026-04-06 08:00:00', 100.000, 90.000, 'Failed');

-- --------------------------------------------------------

--
-- Table structure for table `reagent_batch`
--

CREATE TABLE `reagent_batch` (
  `batch_id` int(11) NOT NULL,
  `test_id` int(11) NOT NULL,
  `batch_number` varchar(100) NOT NULL,
  `manufacturer` varchar(100) DEFAULT NULL,
  `received_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL
) ;

--
-- Dumping data for table `reagent_batch`
--

INSERT INTO `reagent_batch` (`batch_id`, `test_id`, `batch_number`, `manufacturer`, `received_date`, `expiry_date`) VALUES
(1, 1, 'BATCH-001', 'ReagentCo', '2026-01-01', '2027-01-01'),
(2, 1, 'BATCH-002', 'ReagentCo', '2026-03-01', '2027-03-01');

-- --------------------------------------------------------

--
-- Table structure for table `test_order`
--

CREATE TABLE `test_order` (
  `order_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `test_id` int(11) NOT NULL,
  `order_date` datetime NOT NULL,
  `order_status` varchar(30) NOT NULL
) ;

--
-- Dumping data for table `test_order`
--

INSERT INTO `test_order` (`order_id`, `patient_id`, `test_id`, `order_date`, `order_status`) VALUES
(1, 1, 1, '2026-04-01 09:00:00', 'Completed'),
(2, 2, 1, '2026-04-01 10:00:00', 'Completed'),
(3, 3, 1, '2026-04-02 09:30:00', 'Completed'),
(4, 1, 1, '2026-04-05 11:00:00', 'Completed'),
(5, 4, 1, '2026-04-06 12:00:00', 'Completed'),
(6, 5, 1, '2026-04-07 14:00:00', 'Pending'),
(7, 2, 1, '2026-11-02 17:06:06', 'Completed'),
(8, 3, 1, '2026-11-02 17:07:58', 'Completed');

-- --------------------------------------------------------

--
-- Table structure for table `test_performance`
--

CREATE TABLE `test_performance` (
  `performance_id` int(11) NOT NULL,
  `test_id` int(11) NOT NULL,
  `disease_id` int(11) NOT NULL,
  `sensitivity` decimal(6,5) NOT NULL,
  `specificity` decimal(6,5) NOT NULL,
  `source_reference` varchar(500) NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL
) ;

--
-- Dumping data for table `test_performance`
--

INSERT INTO `test_performance` (`performance_id`, `test_id`, `disease_id`, `sensitivity`, `specificity`, `source_reference`, `effective_from`, `effective_to`) VALUES
(1, 1, 1, 0.95000, 0.98000, 'Illustrative simulation assumption; not a clinical estimate.', '2026-01-01', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `test_result`
--

CREATE TABLE `test_result` (
  `result_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `equipment_id` int(11) NOT NULL,
  `batch_id` int(11) NOT NULL,
  `performed_at` datetime NOT NULL,
  `result_value` decimal(10,3) DEFAULT NULL,
  `interpretation` varchar(30) DEFAULT NULL
) ;

--
-- Dumping data for table `test_result`
--

INSERT INTO `test_result` (`result_id`, `order_id`, `equipment_id`, `batch_id`, `performed_at`, `result_value`, `interpretation`) VALUES
(1, 1, 1, 1, '2026-04-01 09:20:00', 1.000, 'Positive'),
(2, 2, 1, 1, '2026-04-01 10:20:00', 0.000, 'Negative'),
(3, 3, 2, 1, '2026-04-02 09:50:00', 1.000, 'Positive'),
(4, 4, 1, 2, '2026-04-05 11:20:00', 0.000, 'Negative'),
(5, 5, 3, 2, '2026-04-06 12:20:00', 1.000, 'Positive'),
(6, 7, 1, 1, '2026-11-02 17:06:06', 1.000, 'Positive'),
(7, 8, 1, 1, '2026-11-02 17:08:12', 1.000, 'Positive');

--
-- Triggers `test_result`
--
DELIMITER $$
CREATE TRIGGER `trg_validate_test_result` BEFORE INSERT ON `test_result` FOR EACH ROW BEGIN
    DECLARE v_order_test_id INT;
    DECLARE v_batch_test_id INT;
    DECLARE v_expiry_date DATE;

    SELECT test_id
    INTO v_order_test_id
    FROM TEST_ORDER
    WHERE order_id = NEW.order_id;

    SELECT test_id, expiry_date
    INTO v_batch_test_id, v_expiry_date
    FROM REAGENT_BATCH
    WHERE batch_id = NEW.batch_id;

    IF v_order_test_id <> v_batch_test_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Reagent batch does not match the diagnostic test';
    END IF;

    IF v_expiry_date IS NOT NULL
       AND DATE(NEW.performed_at) > v_expiry_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Expired reagent batch cannot be used';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_validate_test_result_update` BEFORE UPDATE ON `test_result` FOR EACH ROW BEGIN
    DECLARE v_order_test_id INT;
    DECLARE v_batch_test_id INT;
    DECLARE v_expiry_date DATE;

    SELECT test_id
    INTO v_order_test_id
    FROM TEST_ORDER
    WHERE order_id = NEW.order_id;

    SELECT test_id, expiry_date
    INTO v_batch_test_id, v_expiry_date
    FROM REAGENT_BATCH
    WHERE batch_id = NEW.batch_id;

    IF v_order_test_id <> v_batch_test_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Reagent batch does not match the diagnostic test';
    END IF;

    IF v_expiry_date IS NOT NULL
       AND DATE(NEW.performed_at) > v_expiry_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Expired reagent batch cannot be used';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_diagnostic_history`
-- (See below for the actual view)
--
CREATE TABLE `vw_diagnostic_history` (
`patient_id` int(11)
,`order_id` int(11)
,`test_name` varchar(100)
,`order_date` datetime
,`performed_at` datetime
,`interpretation` varchar(30)
,`serial_number` varchar(100)
,`lab_name` varchar(100)
,`batch_number` varchar(100)
);

-- --------------------------------------------------------

--
-- Structure for view `vw_diagnostic_history`
--
DROP TABLE IF EXISTS `vw_diagnostic_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_diagnostic_history`  AS SELECT `p`.`patient_id` AS `patient_id`, `o`.`order_id` AS `order_id`, `d`.`test_name` AS `test_name`, `o`.`order_date` AS `order_date`, `r`.`performed_at` AS `performed_at`, `r`.`interpretation` AS `interpretation`, `e`.`serial_number` AS `serial_number`, `l`.`lab_name` AS `lab_name`, `rb`.`batch_number` AS `batch_number` FROM ((((((`patient` `p` join `test_order` `o` on(`p`.`patient_id` = `o`.`patient_id`)) join `diagnostic_test` `d` on(`o`.`test_id` = `d`.`test_id`)) join `test_result` `r` on(`o`.`order_id` = `r`.`order_id`)) join `equipment` `e` on(`r`.`equipment_id` = `e`.`equipment_id`)) join `laboratory` `l` on(`e`.`lab_id` = `l`.`lab_id`)) join `reagent_batch` `rb` on(`r`.`batch_id` = `rb`.`batch_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bayesian_assessment`
--
ALTER TABLE `bayesian_assessment`
  ADD PRIMARY KEY (`assessment_id`),
  ADD UNIQUE KEY `result_id` (`result_id`,`performance_id`,`prevalence_id`,`model_version_id`),
  ADD UNIQUE KEY `uq_bayesian_assessment` (`result_id`,`performance_id`,`prevalence_id`,`model_version_id`),
  ADD KEY `performance_id` (`performance_id`),
  ADD KEY `prevalence_id` (`prevalence_id`),
  ADD KEY `model_version_id` (`model_version_id`);

--
-- Indexes for table `calibration`
--
ALTER TABLE `calibration`
  ADD PRIMARY KEY (`calibration_id`),
  ADD KEY `idx_calibration_equipment_date` (`equipment_id`,`calibration_date`);

--
-- Indexes for table `diagnostic_test`
--
ALTER TABLE `diagnostic_test`
  ADD PRIMARY KEY (`test_id`);

--
-- Indexes for table `disease`
--
ALTER TABLE `disease`
  ADD PRIMARY KEY (`disease_id`),
  ADD UNIQUE KEY `disease_name` (`disease_name`);

--
-- Indexes for table `disease_prevalence`
--
ALTER TABLE `disease_prevalence`
  ADD PRIMARY KEY (`prevalence_id`),
  ADD KEY `disease_id` (`disease_id`);

--
-- Indexes for table `equipment`
--
ALTER TABLE `equipment`
  ADD PRIMARY KEY (`equipment_id`),
  ADD UNIQUE KEY `uq_equipment_serial` (`manufacturer`,`serial_number`),
  ADD KEY `fk_equipment_lab` (`lab_id`);

--
-- Indexes for table `equipment_reliability_assessment`
--
ALTER TABLE `equipment_reliability_assessment`
  ADD PRIMARY KEY (`reliability_assessment_id`),
  ADD UNIQUE KEY `equipment_id` (`equipment_id`,`model_version_id`,`observation_start`,`observation_end`),
  ADD KEY `model_version_id` (`model_version_id`);

--
-- Indexes for table `laboratory`
--
ALTER TABLE `laboratory`
  ADD PRIMARY KEY (`lab_id`);

--
-- Indexes for table `maintenance`
--
ALTER TABLE `maintenance`
  ADD PRIMARY KEY (`maintenance_id`),
  ADD KEY `fk_maintenance_equipment` (`equipment_id`);

--
-- Indexes for table `model_version`
--
ALTER TABLE `model_version`
  ADD PRIMARY KEY (`model_version_id`),
  ADD UNIQUE KEY `model_name` (`model_name`,`version_number`);

--
-- Indexes for table `patient`
--
ALTER TABLE `patient`
  ADD PRIMARY KEY (`patient_id`);

--
-- Indexes for table `quality_control`
--
ALTER TABLE `quality_control`
  ADD PRIMARY KEY (`qc_id`),
  ADD KEY `idx_qc_equipment_date` (`equipment_id`,`observation_date`);

--
-- Indexes for table `reagent_batch`
--
ALTER TABLE `reagent_batch`
  ADD PRIMARY KEY (`batch_id`),
  ADD UNIQUE KEY `uq_reagent_batch` (`manufacturer`,`batch_number`),
  ADD KEY `idx_batch_test_expiry` (`test_id`,`expiry_date`);

--
-- Indexes for table `test_order`
--
ALTER TABLE `test_order`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `fk_order_test` (`test_id`),
  ADD KEY `idx_order_patient_date` (`patient_id`,`order_date`);

--
-- Indexes for table `test_performance`
--
ALTER TABLE `test_performance`
  ADD PRIMARY KEY (`performance_id`),
  ADD UNIQUE KEY `test_id` (`test_id`,`disease_id`,`effective_from`),
  ADD KEY `disease_id` (`disease_id`);

--
-- Indexes for table `test_result`
--
ALTER TABLE `test_result`
  ADD PRIMARY KEY (`result_id`),
  ADD UNIQUE KEY `order_id` (`order_id`),
  ADD KEY `fk_result_batch` (`batch_id`),
  ADD KEY `idx_result_equipment_date` (`equipment_id`,`performed_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bayesian_assessment`
--
ALTER TABLE `bayesian_assessment`
  MODIFY `assessment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `calibration`
--
ALTER TABLE `calibration`
  MODIFY `calibration_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `diagnostic_test`
--
ALTER TABLE `diagnostic_test`
  MODIFY `test_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `disease`
--
ALTER TABLE `disease`
  MODIFY `disease_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `disease_prevalence`
--
ALTER TABLE `disease_prevalence`
  MODIFY `prevalence_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `equipment`
--
ALTER TABLE `equipment`
  MODIFY `equipment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `equipment_reliability_assessment`
--
ALTER TABLE `equipment_reliability_assessment`
  MODIFY `reliability_assessment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `laboratory`
--
ALTER TABLE `laboratory`
  MODIFY `lab_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `maintenance`
--
ALTER TABLE `maintenance`
  MODIFY `maintenance_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `model_version`
--
ALTER TABLE `model_version`
  MODIFY `model_version_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `patient`
--
ALTER TABLE `patient`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `quality_control`
--
ALTER TABLE `quality_control`
  MODIFY `qc_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reagent_batch`
--
ALTER TABLE `reagent_batch`
  MODIFY `batch_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `test_order`
--
ALTER TABLE `test_order`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `test_performance`
--
ALTER TABLE `test_performance`
  MODIFY `performance_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `test_result`
--
ALTER TABLE `test_result`
  MODIFY `result_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bayesian_assessment`
--
ALTER TABLE `bayesian_assessment`
  ADD CONSTRAINT `bayesian_assessment_ibfk_1` FOREIGN KEY (`result_id`) REFERENCES `test_result` (`result_id`),
  ADD CONSTRAINT `bayesian_assessment_ibfk_2` FOREIGN KEY (`performance_id`) REFERENCES `test_performance` (`performance_id`),
  ADD CONSTRAINT `bayesian_assessment_ibfk_3` FOREIGN KEY (`prevalence_id`) REFERENCES `disease_prevalence` (`prevalence_id`),
  ADD CONSTRAINT `bayesian_assessment_ibfk_4` FOREIGN KEY (`model_version_id`) REFERENCES `model_version` (`model_version_id`);

--
-- Constraints for table `calibration`
--
ALTER TABLE `calibration`
  ADD CONSTRAINT `fk_calibration_equipment` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`);

--
-- Constraints for table `disease_prevalence`
--
ALTER TABLE `disease_prevalence`
  ADD CONSTRAINT `disease_prevalence_ibfk_1` FOREIGN KEY (`disease_id`) REFERENCES `disease` (`disease_id`);

--
-- Constraints for table `equipment`
--
ALTER TABLE `equipment`
  ADD CONSTRAINT `fk_equipment_lab` FOREIGN KEY (`lab_id`) REFERENCES `laboratory` (`lab_id`);

--
-- Constraints for table `equipment_reliability_assessment`
--
ALTER TABLE `equipment_reliability_assessment`
  ADD CONSTRAINT `equipment_reliability_assessment_ibfk_1` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`),
  ADD CONSTRAINT `equipment_reliability_assessment_ibfk_2` FOREIGN KEY (`model_version_id`) REFERENCES `model_version` (`model_version_id`);

--
-- Constraints for table `maintenance`
--
ALTER TABLE `maintenance`
  ADD CONSTRAINT `fk_maintenance_equipment` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`);

--
-- Constraints for table `quality_control`
--
ALTER TABLE `quality_control`
  ADD CONSTRAINT `fk_qc_equipment` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`);

--
-- Constraints for table `reagent_batch`
--
ALTER TABLE `reagent_batch`
  ADD CONSTRAINT `fk_reagent_test` FOREIGN KEY (`test_id`) REFERENCES `diagnostic_test` (`test_id`);

--
-- Constraints for table `test_order`
--
ALTER TABLE `test_order`
  ADD CONSTRAINT `fk_order_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`),
  ADD CONSTRAINT `fk_order_test` FOREIGN KEY (`test_id`) REFERENCES `diagnostic_test` (`test_id`);

--
-- Constraints for table `test_performance`
--
ALTER TABLE `test_performance`
  ADD CONSTRAINT `test_performance_ibfk_1` FOREIGN KEY (`test_id`) REFERENCES `diagnostic_test` (`test_id`),
  ADD CONSTRAINT `test_performance_ibfk_2` FOREIGN KEY (`disease_id`) REFERENCES `disease` (`disease_id`);

--
-- Constraints for table `test_result`
--
ALTER TABLE `test_result`
  ADD CONSTRAINT `fk_result_batch` FOREIGN KEY (`batch_id`) REFERENCES `reagent_batch` (`batch_id`),
  ADD CONSTRAINT `fk_result_equipment` FOREIGN KEY (`equipment_id`) REFERENCES `equipment` (`equipment_id`),
  ADD CONSTRAINT `fk_result_order` FOREIGN KEY (`order_id`) REFERENCES `test_order` (`order_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
