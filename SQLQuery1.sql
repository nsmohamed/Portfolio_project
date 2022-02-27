--Cleaning Data in SQL
SELECT *
FROM PortfolioProject.dbo.Nashville_housing;

-------------------------------------------------------------------------
--Standardize Date Format

ALTER TABLE Nashville_housing
Add SaleDateConverted Date;

UPDATE Nashville_housing-- We added another column because the SaleDate didn't convert properly.
SET SaleDateConverted = CONVERT(Date, SaleDateConverted);

SELECT SaleDateConverted, CONVERT(Date,SaleDateConverted) --this is what we want, remove the zeroes
FROM PortfolioProject.dbo.Nashville_housing;

ALTER TABLE Nashville_housing--removed SaleDate so that there is no confusion
DROP COLUMN SaleDate;

-------------------------------------------------------------------------
-- Populate Property Address data

SELECT *
FROM PortfolioProject.dbo.Nashville_housing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;--Parcel ID can be duplicated and it always has the same address, so we populate address Nulls using the identical ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
FROM PortfolioProject.dbo.Nashville_housing a
JOIN PortfolioProject.dbo.Nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL; -- this is what we're looking for, to populate the Nulls

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.Nashville_housing a
JOIN PortfolioProject.dbo.Nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL; -- population successful, check the query above there are no Nulls.

-------------------------------------------------------------------------
--Breaking out address into individual columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioProject.dbo.Nashville_housing;


SELECT 
	LEFT(PropertyAddress,CHARINDEX(',',PropertyAddress)-1) AS Address,
--OR SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) AS Address
	RIGHT(PropertyAddress,(LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress))) AS City
--OR SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS State
FROM PortfolioProject.dbo.Nashville_housing;

ALTER TABLE Nashville_housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE Nashville_housing
SET PropertySplitAddress = LEFT(PropertyAddress,CHARINDEX(',',PropertyAddress)-1);

ALTER TABLE Nashville_housing
ADD PropertySplitCity Nvarchar(255);

UPDATE Nashville_housing
SET PropertySplitCity = RIGHT(PropertyAddress,(LEN(PropertyAddress)-CHARINDEX(',',PropertyAddress)));

SELECT PropertySplitAddress,
		PropertySplitCity
FROM PortfolioProject.dbo.Nashville_housing; -- Added two new columns Great!

--DIFFERENT METHOD Easier than SUBSTRING or LEFT/Right
--SELECT 
--	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
--	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
--	PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--FROM PortfolioProject.dbo.Nashville_housing;


ALTER TABLE Nashville_housing
ADD State Nvarchar(255);

UPDATE Nashville_housing
SET State = PARSENAME(REPLACE(OwnerAddress,',','.'),1); -- Changed to PropertySplitState for continuety

SELECT *
FROM PortfolioProject.dbo.Nashville_housing;

-------------------------------------------------------------------------
--Change T and N to YES and NO for a more uniform data

SELECT DISTINCT (SoldAsVacant),
	COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.Nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant END
FROM PortfolioProject.dbo.Nashville_housing
WHERE SoldAsVacant = 'Y' OR SoldAsVacant = 'N';--Now that we changed them let's make it permanent

UPDATE Nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant END-- update complete, only 'Yes' or 'No' in SoldAsVacant


	-------------------------------------------------------------------------
	--Remove Duplicates
WITH RowNumCTE AS (
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDateConverted,
					 Legalreference
					 ORDER BY
						UniqueID
						) row_num
FROM portfolioproject.dbo.Nashville_housing)
--ORDER BY ParcelID); made it a temp table to be able to query.

SELECT *
FROM RowNumCTE
WHERE row_num >1
ORDER BY PropertyAddress --these are all the duplicates that we'll delete

DELETE
FROM RowNumCTE
WHERE row_num >1; -- Remove all duplicates



-------------------------------------------------------------------------
-- DELETE unused columns


SELECT *
FROM portfolioproject.dbo.Nashville_housing;

ALTER TABLE portfolioproject.dbo.Nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress